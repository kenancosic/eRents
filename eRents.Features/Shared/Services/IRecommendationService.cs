using eRents.Features.PropertyManagement.DTOs;

namespace eRents.Features.Shared.Services
{
    /// <summary>
    /// Service for ML-based property recommendations
    /// Uses Matrix Factorization for personalized property suggestions
    /// </summary>
    public interface IRecommendationService
    {
        #region Core Recommendation Methods

        /// <summary>
        /// Get property recommendations for a specific user based on ratings and preferences
        /// </summary>
        Task<List<PropertyResponse>> GetRecommendationsAsync(int userId, int maxRecommendations = 10, float minScore = 3.5f);
        
        /// <summary>
        /// Get model training status and statistics
        /// </summary>
        Task<RecommendationModelInfo> GetModelInfoAsync();

        #endregion

        #region Alternative Recommendation Methods

        /// <summary>
        /// Get fallback recommendations based on user preferences when ML model is not available
        /// </summary>
        Task<List<PropertyResponse>> GetFallbackRecommendationsAsync(int userId, int maxRecommendations = 10);

        /// <summary>
        /// Get popular properties as recommendations
        /// </summary>
        Task<List<PropertyResponse>> GetPopularPropertiesAsync(int maxRecommendations = 10);

        /// <summary>
        /// Get recommendations based on similar user preferences
        /// </summary>
        Task<List<PropertyResponse>> GetSimilarUserRecommendationsAsync(int userId, int maxRecommendations = 10);

        #endregion

        #region Model Management

        /// <summary>
        /// Check if the ML model needs retraining
        /// </summary>
        Task<bool> ShouldRetrainModelAsync();

        /// <summary>
        /// Force retrain the recommendation model
        /// </summary>
        Task ForceModelRetrainingAsync();

        #endregion
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
        public int MinimumRatingsRequired { get; set; } = 10;
        public bool HasSufficientData { get; set; }
    }
} 