using eRents.Features.ReviewManagement.DTOs;

namespace eRents.Features.ReviewManagement.Services;

/// <summary>
/// Interface for Review management service
/// Following modular architecture principles
/// </summary>
public interface IReviewService
{
	#region Core Review Operations

	/// <summary>
	/// Gets a review by ID
	/// </summary>
	Task<ReviewResponse?> GetReviewByIdAsync(int reviewId);

	/// <summary>
	/// Creates a new review
	/// </summary>
	Task<ReviewResponse> CreateReviewAsync(ReviewRequest request);

	/// <summary>
	/// Updates an existing review
	/// </summary>
	Task<ReviewResponse> UpdateReviewAsync(int reviewId, ReviewRequest request);

	/// <summary>
	/// Deletes a review
	/// </summary>
	Task DeleteReviewAsync(int reviewId);

	/// <summary>
	/// Creates a reply to an existing review
	/// </summary>
	Task<ReviewResponse> CreateReplyAsync(ReviewReplyRequest request);

	#endregion

	#region Review Queries

	/// <summary>
	/// Gets paginated reviews with filtering
	/// </summary>
	Task<ReviewPagedResponse> GetReviewsAsync(ReviewFilterRequest filter);

	/// <summary>
	/// Gets reviews for a specific property
	/// </summary>
	Task<ReviewPagedResponse> GetPropertyReviewsAsync(int propertyId, int page = 1, int pageSize = 10, bool includeReplies = false);

	/// <summary>
	/// Gets reviews by a specific user
	/// </summary>
	Task<ReviewPagedResponse> GetUserReviewsAsync(int userId, int page = 1, int pageSize = 10);

	/// <summary>
	/// Gets replies for a specific review
	/// </summary>
	Task<List<ReviewResponse>> GetReviewRepliesAsync(int parentReviewId);

	/// <summary>
	/// Gets recent reviews across all properties
	/// </summary>
	Task<List<ReviewResponse>> GetRecentReviewsAsync(int count = 10);

	#endregion

	#region Review Statistics

	/// <summary>
	/// Gets review statistics for a property
	/// </summary>
	Task<ReviewStatisticsResponse> GetPropertyStatisticsAsync(int propertyId);

	/// <summary>
	/// Gets user review summary
	/// </summary>
	Task<UserReviewSummaryResponse> GetUserSummaryAsync(int userId);

	/// <summary>
	/// Gets detailed rating breakdown for a property
	/// </summary>
	Task<RatingBreakdownResponse> GetRatingBreakdownAsync(int propertyId);

	/// <summary>
	/// Gets review quality assessment
	/// </summary>

	#endregion



	#region Authorization Helpers

	/// <summary>
	/// Checks if user can review a property
	/// </summary>
	Task<bool> CanUserReviewPropertyAsync(int userId, int propertyId);

	/// <summary>
	/// Checks if user can reply to a review
	/// </summary>
	Task<bool> CanUserReplyToReviewAsync(int userId, int reviewId);

	/// <summary>
	/// Checks if user owns a review
	/// </summary>
	Task<bool> IsReviewOwnerAsync(int userId, int reviewId);

	#endregion


}
