using eRents.Application.Shared;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Shared.SearchObjects;
using eRents.Domain.Shared;
using Microsoft.AspNetCore.Http;

namespace eRents.Application.Services.ReviewService
{
	/// <summary>
	/// ✅ ENHANCED: Clean review service interface with proper SoC
	/// Focuses on review business logic - image management delegated to ImageService
	/// Supports threaded conversations and property review aggregation
	/// </summary>
	public interface IReviewService : ICRUDService<ReviewResponse, ReviewSearchObject, ReviewInsertRequest, ReviewUpdateRequest>
	{
		#region Property Review Methods
		/// <summary>✅ DELEGATION: Simple repository delegation for property rating calculation</summary>
		Task<decimal> GetAverageRatingAsync(int propertyId);
		
		/// <summary>✅ BUSINESS LOGIC: Get original reviews for property with consistent filtering</summary>
		Task<IEnumerable<ReviewResponse>> GetReviewsForPropertyAsync(int propertyId);
		
		/// <summary>✅ ENHANCED: Optimized pagination focusing on original reviews only</summary>
		Task<PagedList<ReviewResponse>> GetPagedReviewsForPropertyAsync(int propertyId, int page = 1, int pageSize = 10);
		#endregion

		#region Threaded Conversation Methods
		/// <summary>✅ BUSINESS LOGIC: Get review with complete reply thread for conversation display</summary>
		Task<ReviewResponse?> GetReviewWithRepliesAsync(int reviewId);
		
		/// <summary>✅ BUSINESS LOGIC: Submit reply to existing review with proper threading</summary>
		Task<ReviewResponse> SubmitReplyAsync(int parentReviewId, ReviewInsertRequest replyRequest);
		#endregion

		#region Review Management
		/// <summary>✅ BUSINESS LOGIC: Delete review with cascade handling for replies</summary>
		Task<bool> DeleteReviewAsync(int reviewId);
		#endregion
	}
}
