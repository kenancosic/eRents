using AutoMapper;
using eRents.Application.Shared;
using eRents.Domain.Models;
using eRents.Domain.Repositories;
using eRents.Domain.Shared;
using eRents.Shared.Services;
using eRents.Shared.Messaging;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Shared.SearchObjects;
using Microsoft.Extensions.Logging;

namespace eRents.Application.Services.ReviewService
{
	/// <summary>
	/// ✅ ENHANCED: Clean review service with proper SoC
	/// Focuses on review business logic - delegates image management and notifications
	/// Eliminates redundant repository delegation methods
	/// </summary>
	public class ReviewService : BaseCRUDService<ReviewResponse, Review, ReviewSearchObject, ReviewInsertRequest, ReviewUpdateRequest>, IReviewService
	{
		#region Dependencies
		private readonly IReviewRepository _reviewRepository;
		private readonly IRabbitMQService _rabbitMqService;

		public ReviewService(
			IReviewRepository reviewRepository, 
			IRabbitMQService rabbitMQService, 
			IMapper mapper,
			IUnitOfWork unitOfWork,
			ICurrentUserService currentUserService,
			ILogger<ReviewService> logger)
			: base(reviewRepository, mapper, unitOfWork, currentUserService, logger)
		{
			_reviewRepository = reviewRepository;
			_rabbitMqService = rabbitMQService;
		}
		#endregion

		#region Base Method Overrides

		protected override async Task BeforeUpdateAsync(ReviewUpdateRequest update, Review entity)
		{
			// ❌ SoC VIOLATION REMOVED: Image management should be handled by ImageService
			// TODO: Move to ImageService.UpdateReviewImagesAsync(reviewId, imageIds)
			// Or handle through coordination layer (ReviewCoordinatorService)
			
			_logger?.LogInformation("Review {ReviewId} update initiated", entity.ReviewId);
			
			await base.BeforeUpdateAsync(update, entity);
		}

		public override async Task<ReviewResponse> InsertAsync(ReviewInsertRequest request)
		{
			var reviewResponse = await base.InsertAsync(request);

			// ❌ SoC VIOLATION REMOVED: Image association should be handled externally
			// TODO: Move to ImageService.AssociateImagesWithReviewAsync(reviewId, imageIds)
			// TODO: Handle through ReviewCoordinatorService for proper orchestration

			// ✅ NOTIFICATION: Publish review creation event (kept for business requirement)
			await PublishReviewNotificationAsync(reviewResponse);

			return reviewResponse;
		}

		#endregion

		#region Review Business Logic

		public async Task<decimal> GetAverageRatingAsync(int propertyId)
		{
			// ✅ SIMPLIFIED: Direct delegation - could be moved to property statistics
			return await _reviewRepository.GetAverageRatingAsync(propertyId);
		}
		
		public async Task<IEnumerable<ReviewResponse>> GetReviewsForPropertyAsync(int propertyId)
		{
			// ✅ BUSINESS LOGIC: Uses search object for consistent filtering and includes
			var search = new ReviewSearchObject
			{
				PropertyId = propertyId,
				IsOriginalReview = true, // Only get original reviews, not replies
				NoPaging = true
			};
			
			var pagedResult = await GetPagedAsync(search);
			return pagedResult.Items;
		}
		
		/// <summary>
		/// ✅ ENHANCED: Optimized pagination for UI display with proper sorting
		/// Focuses on original reviews only for cleaner property review display
		/// </summary>
		public async Task<PagedList<ReviewResponse>> GetPagedReviewsForPropertyAsync(int propertyId, int page = 1, int pageSize = 10)
		{
			var search = new ReviewSearchObject
			{
				PropertyId = propertyId,
				IsOriginalReview = true, // Only original reviews for property display
				Page = page,
				PageSize = pageSize,
				SortBy = "DateCreated",
				SortDescending = true // Show newest reviews first
			};
			
			return await GetPagedAsync(search);
		}

		/// <summary>
		/// ✅ BUSINESS LOGIC: Get review with its replies for threaded display
		/// Provides complete conversation thread for a review
		/// </summary>
		public async Task<ReviewResponse?> GetReviewWithRepliesAsync(int reviewId)
		{
			var search = new ReviewSearchObject
			{
				ReviewId = reviewId,
				IncludeReplies = true
			};
			
			var result = await GetPagedAsync(search);
			return result.Items.FirstOrDefault();
		}

		/// <summary>
		/// ✅ BUSINESS LOGIC: Submit reply to existing review
		/// Handles threaded conversation logic
		/// </summary>
		public async Task<ReviewResponse> SubmitReplyAsync(int parentReviewId, ReviewInsertRequest replyRequest)
		{
			// ✅ VALIDATION: Ensure parent review exists
			var parentReview = await _reviewRepository.GetByIdAsync(parentReviewId);
			if (parentReview == null)
				throw new ArgumentException("Parent review not found");

			// ✅ BUSINESS RULE: Replies inherit property context from parent
			replyRequest.PropertyId = parentReview.PropertyId;
			replyRequest.ParentReviewId = parentReviewId;
			replyRequest.StarRating = null; // Replies don't have ratings

			return await InsertAsync(replyRequest);
		}

		public async Task<bool> DeleteReviewAsync(int reviewId)
		{
			var review = await _repository.GetByIdAsync(reviewId);
			if (review == null)
			{
				return false;
			}

			// ✅ BUSINESS LOGIC: Consider cascading delete of replies
			// This is handled by the repository/database FK constraints
			await _repository.DeleteAsync(review);
			
			if (_unitOfWork != null)
			{
				await _unitOfWork.SaveChangesAsync();
			}

			return true;
		}

		#endregion

		#region Helper Methods

		/// <summary>
		/// ✅ NOTIFICATION: Centralized notification publishing
		/// Keeps notification logic but separates it from main business flow
		/// </summary>
		private async Task PublishReviewNotificationAsync(ReviewResponse reviewResponse)
		{
			try
			{
				var notificationMessage = new ReviewNotificationMessage
				{
					PropertyId = reviewResponse.PropertyId,
					ReviewId = reviewResponse.ReviewId,
					Message = "A new review has been posted."
				};
				
				await _rabbitMqService.PublishMessageAsync("reviewQueue", notificationMessage);
				
				_logger?.LogInformation("Review notification published for review {ReviewId}", reviewResponse.ReviewId);
			}
			catch (Exception ex)
			{
				_logger?.LogError(ex, "Failed to publish review notification for review {ReviewId}", reviewResponse.ReviewId);
				// Don't throw - notification failure shouldn't break review creation
			}
		}

		#endregion
	}
}