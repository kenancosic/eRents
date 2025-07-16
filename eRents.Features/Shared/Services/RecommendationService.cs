using eRents.Domain.Models;
using eRents.Domain.Shared;
using eRents.Features.PropertyManagement.DTOs;
using eRents.Domain.Shared.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.ML;
using Microsoft.ML.Trainers;

namespace eRents.Features.Shared.Services
{
	/// <summary>
	/// ML-based property recommendation service using direct ERentsContext access
	/// Provides fallback recommendations when ML model is not available
	/// </summary>
	public class RecommendationService : IRecommendationService
	{
		private readonly ERentsContext _context;
		private readonly IUnitOfWork _unitOfWork;
		private readonly ICurrentUserService _currentUserService;
		private readonly ILogger<RecommendationService> _logger;

		// ML.NET components with thread-safe access
		private static MLContext? _mlContext = null;
		private static ITransformer? _model = null;
		private static readonly object _lock = new object();
		private static DateTime? _lastTrainingDate = null;
		private static int _lastTrainingDataCount = 0;

		public RecommendationService(
				ERentsContext context,
				IUnitOfWork unitOfWork,
				ICurrentUserService currentUserService,
				ILogger<RecommendationService> logger)
		{
			_context = context;
			_unitOfWork = unitOfWork;
			_currentUserService = currentUserService;
			_logger = logger;

			// Initialize ML context and load model on startup
			lock (_lock)
			{
				if (_mlContext == null)
				{
					_mlContext = new MLContext(seed: 0);
					_logger.LogInformation("Initialized MLContext for recommendations.");
					// Load the model synchronously on startup
					LoadModelAsync().GetAwaiter().GetResult();
				}
			}
		}

		#region Core Recommendation Methods

		public async Task<List<PropertyResponse>> GetRecommendationsAsync(int userId, int maxRecommendations = 10, float minScore = 3.5f)
		{
			try
			{


				// Try ML recommendations first
				var mlRecommendations = await TryGetMLRecommendationsAsync(userId, maxRecommendations, minScore);
				if (mlRecommendations.Any())
				{
					return mlRecommendations;
				}

				// Fall back to preference-based recommendations
				_logger.LogInformation("ML model not available, using fallback recommendations for user {UserId}", userId);
				return await GetFallbackRecommendationsAsync(userId, maxRecommendations);
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error generating recommendations for user {UserId}", userId);
				return await GetPopularPropertiesAsync(maxRecommendations);
			}
		}

		public async Task<RecommendationModelInfo> GetModelInfoAsync()
		{
			try
			{
				var totalReviews = await _context.Reviews
						.Where(r => r.StarRating > 0)
						.CountAsync();

				return new RecommendationModelInfo
				{
					IsModelTrained = _model != null,
					TotalRatingsUsed = _lastTrainingDataCount,
					LastTrainingDate = _lastTrainingDate,
					ModelStatus = _model != null ? "Trained and Ready" : "Not Trained",
					MinimumRatingsRequired = 10,
					HasSufficientData = totalReviews >= 10
				};
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error getting model info");
				return new RecommendationModelInfo { ModelStatus = "Error" };
			}
		}

		#endregion

		#region Model Management

		private async Task LoadModelAsync()
		{
			try
			{
				var modelPath = Path.Combine(AppContext.BaseDirectory, "recommendation_model.zip");
				if (File.Exists(modelPath))
				{
					lock (_lock)
					{
						if (_model == null) // Check again inside lock
						{
							_model = _mlContext.Model.Load(modelPath, out var schema);
							_lastTrainingDate = File.GetLastWriteTimeUtc(modelPath);
							_logger.LogInformation("Successfully loaded pre-trained recommendation model.");
						}
					}
				}
				else
				{
					_logger.LogInformation("No pre-trained model found. Model will be trained on first relevant request.");
				}
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error loading the recommendation model.");
			}
		}

		#endregion

		#region Alternative Recommendation Methods

		public async Task<List<PropertyResponse>> GetFallbackRecommendationsAsync(int userId, int maxRecommendations = 10)
		{
			try
			{
				// Get user's previous ratings to understand preferences
				var userRatings = await _context.Reviews
						.Where(r => r.Reviewer.UserId == userId && r.StarRating > 0)
						.Include(r => r.Property)
						.ToListAsync();

				// Get user's rental requests to understand property preferences
				var userRequests = await _context.RentalRequests
						.Where(rr => rr.UserId == userId)
						.Include(rr => rr.Property)
						.ToListAsync();

				// Determine preferred price range
				var preferredPriceRange = GetPreferredPriceRange(userRatings, userRequests);

				// Get available properties in preferred price range
				var recommendedProperties = await _context.Properties
						.Where(p => p.Status == "Available" &&
											 p.Price >= preferredPriceRange.Min &&
											 p.Price <= preferredPriceRange.Max)
						.Where(p => !userRatings.Any(r => r.PropertyId == p.PropertyId)) // Exclude already rated
						.OrderByDescending(p => p.CreatedAt) // Order by creation date (newest first)
						.Take(maxRecommendations)
						.ToListAsync();

				return MapToPropertyResponses(recommendedProperties);
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error generating fallback recommendations for user {UserId}", userId);
				return await GetPopularPropertiesAsync(maxRecommendations);
			}
		}

		public async Task<List<PropertyResponse>> GetPopularPropertiesAsync(int maxRecommendations = 10)
		{
			var popularProperties = await _context.Properties
					.Where(p => p.Status == "Available")
					.OrderByDescending(p => p.Reviews.Count)
					.ThenByDescending(p => p.Bookings.Count)
					.Take(maxRecommendations)
					.ToListAsync();

			return MapToPropertyResponses(popularProperties);
		}

		public async Task<List<PropertyResponse>> GetSimilarUserRecommendationsAsync(int userId, int maxRecommendations = 10)
		{
			try
			{
				// Find users with similar rating patterns
				var userRatings = await _context.Reviews
						.Where(r => r.Reviewer.UserId == userId && r.StarRating > 0)
						.Select(r => r.PropertyId)
						.ToListAsync();

				if (!userRatings.Any())
				{
					return await GetPopularPropertiesAsync(maxRecommendations);
				}

				// Find users who rated the same properties highly
				var similarUsers = await _context.Reviews
						.Where(r => userRatings.Contains(r.PropertyId) &&
											 r.Reviewer.UserId != userId &&
											 r.StarRating >= 4)
						.GroupBy(r => r.Reviewer.UserId)
						.Where(g => g.Count() >= 2) // At least 2 similar ratings
						.Select(g => g.Key)
						.Take(10)
						.ToListAsync();

				// Get properties that similar users rated highly
				var recommendedPropertyIds = await _context.Reviews
						.Where(r => similarUsers.Contains(r.Reviewer.UserId) &&
											 !userRatings.Contains(r.PropertyId) &&
											 r.StarRating >= 4)
						.GroupBy(r => r.PropertyId)
						.OrderByDescending(g => g.Count())
						.Take(maxRecommendations)
						.Select(g => g.Key)
						.ToListAsync();

				var properties = await _context.Properties
						.Where(p => recommendedPropertyIds.Contains(p.PropertyId) && p.Status == "Available")
						.ToListAsync();

				return MapToPropertyResponses(properties);
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error generating similar user recommendations for user {UserId}", userId);
				return await GetPopularPropertiesAsync(maxRecommendations);
			}
		}

		#endregion

		#region Model Management

		public async Task<bool> ShouldRetrainModelAsync()
		{
			try
			{
				var totalReviews = await _context.Reviews
						.Where(r => r.StarRating > 0)
						.CountAsync();

				// Retrain if no model exists and we have enough data
				if (_model == null && totalReviews >= 10)
					return true;

				// Retrain if significant new data since last training
				if (_lastTrainingDataCount > 0 && totalReviews > _lastTrainingDataCount * 1.5)
					return true;

				// Retrain if model is older than 7 days
				if (_lastTrainingDate.HasValue && DateTime.UtcNow.Subtract(_lastTrainingDate.Value).Days > 7)
					return true;

				return false;
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error checking if model should retrain");
				return false;
			}
		}

		public async Task ForceModelRetrainingAsync()
		{
			await RetrainModelAsync();
		}

		#endregion

		#region Private Helper Methods

		private async Task<List<PropertyResponse>> TryGetMLRecommendationsAsync(int userId, int maxRecommendations, float minScore)
		{
			try
			{
				// Ensure model is trained
				if (await ShouldRetrainModelAsync())
				{
					await RetrainModelAsync();
				}

				if (_model == null || _mlContext == null)
				{
					return new List<PropertyResponse>();
				}

				// Get available properties for recommendations
				var availableProperties = await _context.Properties
						.Where(p => p.Status == "Available")
						.ToListAsync();

				if (!availableProperties.Any())
				{
					return new List<PropertyResponse>();
				}

				// Generate predictions
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
							recommendedProperties.Add((Property: property, Score: prediction.Score));
						}
					}
					catch (Exception ex)
					{
						_logger.LogWarning(ex, "Failed to generate prediction for property {PropertyId}", property.PropertyId);
					}
				}

				var topRecommendations = recommendedProperties
						.OrderByDescending(x => x.Score)
						.Take(maxRecommendations)
						.Select(x => x.Property)
						.ToList();

				return MapToPropertyResponses(topRecommendations);
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error generating ML recommendations");
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
				var reviewData = await _context.Reviews
						.Where(r => r.StarRating > 0)
						.Select(r => new PropertyRating
						{
							UserId = r.Reviewer.UserId,
							PropertyId = r.Property.PropertyId,
							Label = (float)r.StarRating
						})
						.ToListAsync();

				if (reviewData.Count < 10)
				{
					_logger.LogWarning("Not enough review data ({Count}) to train the model.", reviewData.Count);
					return;
				}

				var mlData = new MLContext(seed: 0);
				var dataView = mlData.Data.LoadFromEnumerable(reviewData);

				var options = new MatrixFactorizationTrainer.Options
				{
					MatrixColumnIndexColumnName = "UserId",
					MatrixRowIndexColumnName = "PropertyId",
					LabelColumnName = "Label",
					NumberOfIterations = 20,
					ApproximationRank = Math.Min(100, reviewData.Count / 2),
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

				// Save the model to a file for persistence
				try
				{
					var modelPath = Path.Combine(AppContext.BaseDirectory, "recommendation_model.zip");
					_mlContext.Model.Save(_model, dataView.Schema, modelPath);
					_logger.LogInformation("Successfully saved the trained model to {Path}", modelPath);
				}
				catch (Exception ex)
				{
					_logger.LogError(ex, "Failed to save the ML model after retraining.");
				}
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error during model retraining");
			}
		}

		private (decimal Min, decimal Max) GetPreferredPriceRange(List<Review> userRatings, List<RentalRequest> userRequests)
		{
			var prices = new List<decimal>();

			// Add prices from highly rated properties
			prices.AddRange(userRatings
					.Where(r => r.StarRating >= 4 && r.Property != null)
					.Select(r => r.Property.Price));

			// Add prices from user requests
			prices.AddRange(userRequests
					.Where(rr => rr.Property != null)
					.Select(rr => rr.Property.Price));

			if (!prices.Any())
			{
				return (0, 10000); // Default broad range
			}

			var avgPrice = prices.Average();
			var minPrice = Math.Max(0, avgPrice * 0.7m);
			var maxPrice = avgPrice * 1.5m;

			return (minPrice, maxPrice);
		}

		private List<PropertyResponse> MapToPropertyResponses(List<Property> properties)
		{
			return properties.Select(p => new PropertyResponse
			{
				Id = p.PropertyId,
				PropertyId = p.PropertyId,
				Name = p.Name,
				Description = p.Description,
				Price = p.Price,
				Currency = p.Currency,
				Status = p.Status,
				OwnerId = p.OwnerId,
				PropertyTypeId = p.PropertyTypeId,
				RentingTypeId = p.RentingTypeId,
				Bedrooms = p.Bedrooms,
				Bathrooms = p.Bathrooms,
				Area = p.Area,
				MinimumStayDays = p.MinimumStayDays,
				RequiresApproval = p.RequiresApproval,
				CreatedAt = p.CreatedAt,
				UpdatedAt = p.UpdatedAt,
				// Address properties
				StreetLine1 = p.Address?.StreetLine1,
				StreetLine2 = p.Address?.StreetLine2,
				City = p.Address?.City,
				State = p.Address?.State,
				Country = p.Address?.Country,
				PostalCode = p.Address?.PostalCode,
				Latitude = p.Address?.Latitude,
				Longitude = p.Address?.Longitude,
				// Navigation properties
				OwnerName = p.Owner != null ? $"{p.Owner.FirstName} {p.Owner.LastName}".Trim() : null,
				PropertyTypeName = p.PropertyType?.TypeName,
				RentingTypeName = p.RentingType?.TypeName,
				ImageIds = p.Images?.Select(i => i.ImageId).ToList(),
				AmenityIds = p.Amenities?.Select(a => a.AmenityId).ToList()
			}).ToList();
		}

		#endregion
	}

	#region ML.NET Data Models

	public class PropertyRating
	{
		public float UserId { get; set; }
		public float PropertyId { get; set; }
		public float Label { get; set; }
	}

	public class PropertyRatingPrediction
	{
		public float Score { get; set; }
	}

	#endregion
}