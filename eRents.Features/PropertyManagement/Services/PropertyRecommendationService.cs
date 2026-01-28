using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using eRents.Domain.Models;
using eRents.Domain.Models.Enums;
using eRents.Features.PropertyManagement.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.ML;
using Microsoft.ML.Data;
using Microsoft.ML.Trainers;

namespace eRents.Features.PropertyManagement.Services
{
	public class PropertyRecommendationService : IPropertyRecommendationService
	{
		private readonly ERentsContext _context;
		private static ITransformer _model;
		private static MLContext _mlContext;
		private static readonly object _lock = new object();

		public PropertyRecommendationService(ERentsContext context)
		{
			_context = context;
			_mlContext = new MLContext(seed: 0);
		}

		public async Task<List<PropertyRecommendation>> GetRecommendationsAsync(int userId, int count = 10)
		{
			// Ensure model is trained
			if (_model == null)
			{
				await TrainModelAsync();
			}

			var predictions = new List<(int PropertyId, float Score)>();
		
			// Get properties that are available AND don't have conflicts
			// For monthly properties: exclude those with any active bookings or tenants
			// For daily properties: just check status (availability is date-specific)
			var today = DateOnly.FromDateTime(DateTime.UtcNow.Date);
			var properties = await _context.Properties
				.Include(p => p.Bookings)
				.Where(p => p.Status == PropertyStatusEnum.Available)
				.Where(p => 
					// For monthly rentals: exclude properties with any non-cancelled bookings from today onward
					p.RentingType != RentalType.Monthly ||
					!p.Bookings.Any(b => 
						b.Status != BookingStatusEnum.Cancelled &&
						(b.EndDate.HasValue ? b.EndDate.Value >= today : b.StartDate >= today)))
				.ToListAsync();

			foreach (var property in properties)
			{
				var prediction = await GetPredictionAsync(userId, property.PropertyId);
				predictions.Add((property.PropertyId, prediction));
			}

			// Sort by predicted rating and take top count
			var topPredictions = predictions
				.OrderByDescending(p => p.Score)
				.Take(count)
				.ToList();

			// Convert to PropertyRecommendation objects
			var recommendations = new List<PropertyRecommendation>();
			foreach (var (propertyId, score) in topPredictions)
			{
				var property = properties.First(p => p.PropertyId == propertyId);
				recommendations.Add(new PropertyRecommendation
				{
					PropertyId = property.PropertyId,
					PropertyName = property.Name,
					PropertyDescription = property.Description ?? "",
					Price = property.Price,
					Currency = property.Currency,
					PredictedRating = score
				});
			}

			return recommendations;
		}

		public async Task<List<PropertyRecommendation>> GetSimilarPropertiesAsync(int userId, int propertyId, int count = 4)
		{
			// Ensure model is trained
			if (_model == null)
			{
				await TrainModelAsync();
			}

			// Get the current property to find similar ones
			var currentProperty = await _context.Properties.FindAsync(propertyId);
			if (currentProperty == null)
			{
				return new List<PropertyRecommendation>();
			}

			var predictions = new List<(int PropertyId, float Score)>();

			// Get available properties excluding the current one
			var today = DateOnly.FromDateTime(DateTime.UtcNow.Date);
			var properties = await _context.Properties
				.Include(p => p.Bookings)
				.Where(p => p.PropertyId != propertyId) // Exclude current property
				.Where(p => p.Status == PropertyStatusEnum.Available)
				.Where(p =>
					p.RentingType != RentalType.Monthly ||
					!p.Bookings.Any(b =>
						b.Status != BookingStatusEnum.Cancelled &&
						(b.EndDate.HasValue ? b.EndDate.Value >= today : b.StartDate >= today)))
				.ToListAsync();

			foreach (var property in properties)
			{
				var prediction = await GetPredictionAsync(userId, property.PropertyId);
				predictions.Add((property.PropertyId, prediction));
			}

			// Sort by predicted rating and take top count
			var topPredictions = predictions
				.OrderByDescending(p => p.Score)
				.Take(count)
				.ToList();

			// Convert to PropertyRecommendation objects
			var recommendations = new List<PropertyRecommendation>();
			foreach (var (propId, score) in topPredictions)
			{
				var property = properties.First(p => p.PropertyId == propId);
				recommendations.Add(new PropertyRecommendation
				{
					PropertyId = property.PropertyId,
					PropertyName = property.Name,
					PropertyDescription = property.Description ?? "",
					Price = property.Price,
					Currency = property.Currency,
					PredictedRating = score
				});
			}

			return recommendations;
		}

		public async Task<float> GetPredictionAsync(int userId, int propertyId)
		{
			if (_model == null)
			{
				await TrainModelAsync();
			}

			var predictionEngine = _mlContext.Model.CreatePredictionEngine<UserPropertyRating, RatingPrediction>(_model);
			var input = new UserPropertyRating { UserId = userId, PropertyId = propertyId, Rating = 0 };
			var prediction = predictionEngine.Predict(input);
			// Clamp the prediction to a valid range to prevent infinity/NaN values
			if (float.IsInfinity(prediction.Score) || float.IsNaN(prediction.Score))
			{
				return 0.0f;
			}
			return Math.Max(-10.0f, Math.Min(10.0f, prediction.Score));
		}

		public async Task TrainModelAsync()
		{
			// Get rating data from reviews only
			var ratings = await GetRatingsFromDataAsync();

			if (ratings.Count == 0)
			{
				// No review data available - cannot train model
				// Ensure database has review data before using recommendations
				throw new InvalidOperationException("No review data available for training recommendation model. Please populate the Reviews table with user ratings.");
			}

			// Load data into IDataView
			var data = _mlContext.Data.LoadFromEnumerable(ratings);

			// Create pipeline
			var options = new MatrixFactorizationTrainer.Options
			{
				MatrixColumnIndexColumnName = nameof(UserPropertyRating.UserId),
				MatrixRowIndexColumnName = nameof(UserPropertyRating.PropertyId),
				LabelColumnName = nameof(UserPropertyRating.Rating),
				NumberOfIterations = 100,
				ApproximationRank = 8
			};

			var pipeline = _mlContext.Transforms.Conversion.MapValueToKey(nameof(UserPropertyRating.UserId), nameof(UserPropertyRating.UserId))
				.Append(_mlContext.Transforms.Conversion.MapValueToKey(nameof(UserPropertyRating.PropertyId), nameof(UserPropertyRating.PropertyId)))
				.Append(_mlContext.Recommendation().Trainers.MatrixFactorization(options));

			// Train model
			_model = pipeline.Fit(data);
		}

		private async Task<List<UserPropertyRating>> GetRatingsFromDataAsync()
		{
			var ratings = new List<UserPropertyRating>();

			// Get ratings from reviews (1-5 star scale) - only explicit feedback
			var reviews = await _context.Reviews
				.Where(r => r.StarRating.HasValue && r.ReviewerId.HasValue && r.PropertyId.HasValue)
				.Select(r => new { r.ReviewerId, r.PropertyId, r.StarRating })
				.ToListAsync();

			foreach (var review in reviews)
			{
				ratings.Add(new UserPropertyRating
				{
					UserId = review.ReviewerId.Value,
					PropertyId = review.PropertyId.Value,
					Rating = (float)review.StarRating.Value
				});
			}

			return ratings;
		}
	}

	public class RatingPrediction
	{
		public float Score { get; set; }
	}
}
