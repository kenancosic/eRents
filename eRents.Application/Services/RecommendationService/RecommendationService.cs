using AutoMapper;
using eRents.Domain.Repositories;
using eRents.Shared.DTO.Response;
using Microsoft.Extensions.Logging;
using Microsoft.ML;
using Microsoft.ML.Trainers;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace eRents.Application.Services.RecommendationService
{
	/// <summary>
	/// ML-based property recommendation service using Matrix Factorization
	/// </summary>
	public class RecommendationService : IRecommendationService
	{
		private readonly IReviewRepository _reviewRepository;
		private readonly IPropertyRepository _propertyRepository;
		private readonly IMapper _mapper;
		private readonly ILogger<RecommendationService> _logger;
		
		// ML.NET components with thread-safe access
		private static MLContext? _mlContext = null;
		private static ITransformer? _model = null;
		private static readonly object _lock = new object();
		private static DateTime? _lastTrainingDate = null;
		private static int _lastTrainingDataCount = 0;

		public RecommendationService(
			IReviewRepository reviewRepository,
			IPropertyRepository propertyRepository,
			IMapper mapper,
			ILogger<RecommendationService> logger)
		{
			_reviewRepository = reviewRepository;
			_propertyRepository = propertyRepository;
			_mapper = mapper;
			_logger = logger;
		}

		public async Task<List<PropertyResponse>> GetRecommendationsAsync(int userId, int maxRecommendations = 10, float minScore = 3.5f)
		{
			try
			{
				// Initialize ML context if needed
				lock (_lock)
				{
					if (_mlContext == null)
					{
						_mlContext = new MLContext(seed: 0); // Fixed seed for reproducibility
						_logger.LogInformation("Initialized MLContext for recommendations");
					}
				}

				// Ensure model is trained
				await EnsureModelIsTrainedAsync();

				if (_model == null)
				{
					_logger.LogWarning("Recommendation model is not available, returning empty list");
					return new List<PropertyResponse>();
				}

				// Get available properties for recommendations
				var availableProperties = await _propertyRepository.GetAvailablePropertiesAsync();
				if (!availableProperties.Any())
				{
					_logger.LogInformation("No available properties found for recommendations");
					return new List<PropertyResponse>();
				}

				// Generate predictions for available properties
				var predictionEngine = _mlContext.Model.CreatePredictionEngine<PropertyRating, PropertyRatingPrediction>(_model);
				var recommendedProperties = new List<(Property Property, float Score)>();

				foreach (var property in availableProperties)
				{
					try
					{
						var prediction = predictionEngine.Predict(new PropertyRating 
						{ 
							UserId = userId, 
							PropertyId = property.PropertyId 
						});

						if (prediction.Score >= minScore)
						{
							recommendedProperties.Add((property, prediction.Score));
						}
					}
					catch (Exception ex)
					{
						_logger.LogWarning(ex, "Failed to generate prediction for property {PropertyId}", property.PropertyId);
					}
				}

				// Sort by prediction score and take top recommendations
				var topRecommendations = recommendedProperties
					.OrderByDescending(x => x.Score)
					.Take(maxRecommendations)
					.Select(x => x.Property)
					.ToList();

				_logger.LogInformation("Generated {Count} recommendations for user {UserId}", 
					topRecommendations.Count, userId);

				return _mapper.Map<List<PropertyResponse>>(topRecommendations);
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error generating recommendations for user {UserId}", userId);
				return new List<PropertyResponse>();
			}
		}

		private async Task RetrainModelAsync()
		{
			try
			{
				_logger.LogInformation("Starting model retraining...");

				lock (_lock)
				{
					if (_mlContext == null)
					{
						_mlContext = new MLContext(seed: 0);
					}
				}

				// Get all review data for training
				var allReviews = await _reviewRepository.GetAllAsync();
				var reviewData = allReviews
					.Where(r => r.StarRating.HasValue && r.StarRating.Value > 0)
					.ToList();

				if (reviewData.Count < 10) // Minimum data threshold
				{
					_logger.LogWarning("Insufficient review data for training: {Count} reviews", reviewData.Count);
					return;
				}

				// Convert to ML format
				var mlData = reviewData.Select(r => new PropertyRating
				{
					UserId = (float)r.ReviewerId,
					PropertyId = (float)r.PropertyId,
					Label = (float)r.StarRating.Value
				}).ToList();

				var dataView = _mlContext.Data.LoadFromEnumerable(mlData);

				// Configure Matrix Factorization trainer
				var options = new MatrixFactorizationTrainer.Options
				{
					MatrixColumnIndexColumnName = "UserId",
					MatrixRowIndexColumnName = "PropertyId",
					LabelColumnName = "Label",
					NumberOfIterations = 20,
					ApproximationRank = Math.Min(100, mlData.Count / 2), // Adaptive rank
					LearningRate = 0.1,
					Alpha = 0.01,
					Lambda = 0.025,
					Quiet = true
				};

				lock (_lock)
				{
					var trainer = _mlContext.Recommendation().Trainers.MatrixFactorization(options);
					_model = trainer.Fit(dataView);
					_lastTrainingDate = DateTime.UtcNow;
					_lastTrainingDataCount = reviewData.Count;
				}

				_logger.LogInformation("Model retraining completed with {Count} reviews", reviewData.Count);
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error during model retraining");
				throw;
			}
		}

		public async Task<RecommendationModelInfo> GetModelInfoAsync()
		{
			return await Task.FromResult(new RecommendationModelInfo
			{
				IsModelTrained = _model != null,
				TotalRatingsUsed = _lastTrainingDataCount,
				LastTrainingDate = _lastTrainingDate,
				ModelStatus = _model != null ? "Trained and Ready" : "Not Trained"
			});
		}

		private async Task EnsureModelIsTrainedAsync()
		{
			if (_model == null)
			{
				_logger.LogInformation("Model not found, initiating training...");
				await RetrainModelAsync();
			}
		}
	}

	/// <summary>
	/// Input data format for ML.NET Matrix Factorization
	/// </summary>
	public class PropertyRating
	{
		public float UserId { get; set; }
		public float PropertyId { get; set; }
		public float Label { get; set; }
	}

	/// <summary>
	/// Prediction output from ML.NET model
	/// </summary>
	public class PropertyRatingPrediction
	{
		public float Score { get; set; }
	}
} 