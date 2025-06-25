using eRents.Shared.DTO.Response;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace eRents.Application.Services.RecommendationService
{
	/// <summary>
	/// Service for ML-based property recommendations using Matrix Factorization
	/// </summary>
	public interface IRecommendationService
	{
		/// <summary>
		/// Get property recommendations for a specific user based on ratings and preferences
		/// </summary>
		/// <param name="userId">The user ID to generate recommendations for</param>
		/// <param name="maxRecommendations">Maximum number of recommendations to return (default: 10)</param>
		/// <param name="minScore">Minimum prediction score threshold (default: 3.5)</param>
		/// <returns>List of recommended properties</returns>
		Task<List<PropertyResponse>> GetRecommendationsAsync(int userId, int maxRecommendations = 10, float minScore = 3.5f);
		
		/// <summary>
		/// Get model training status and statistics
		/// </summary>
		Task<RecommendationModelInfo> GetModelInfoAsync();
	}

	/// <summary>
	/// Information about the current recommendation model
	/// </summary>
	public class RecommendationModelInfo
	{
		public bool IsModelTrained { get; set; }
		public int TotalRatingsUsed { get; set; }
		public DateTime? LastTrainingDate { get; set; }
		public string ModelStatus { get; set; } = "Not Trained";
	}
} 