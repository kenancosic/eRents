using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using eRents.Domain.Models;
using eRents.Domain.Models.Enums;
using eRents.Features.ReviewManagement.DTOs;
using eRents.Features.ReviewManagement.Mappers;
using eRents.Domain.Shared.Interfaces;
using eRents.Features.Shared.Services;
using eRents.Domain.Shared;

namespace eRents.Features.ReviewManagement.Services;

/// <summary>
/// Review management service implementation
/// Following unified BaseService architecture with reduced boilerplate
/// </summary>
public class ReviewService : BaseService, IReviewService
{
	public ReviewService(
		ERentsContext context,
		IUnitOfWork unitOfWork,
		ICurrentUserService currentUserService,
		ILogger<ReviewService> logger)
		: base(context, unitOfWork, currentUserService, logger)
	{
	}

	#region Core Review Operations

	public async Task<ReviewResponse?> GetReviewByIdAsync(int reviewId)
	{
		return await GetByIdAsync<Review, ReviewResponse>(
			reviewId,
			q => q.Include(r => r.Replies)
				  .Include(r => r.Reviewer)
				  .Include(r => r.Reviewee)
				  .Include(r => r.Property),
			async review => true, // Reviews are publicly viewable
			review => ReviewMapper.ToDto(review),
			"GetReviewById"
		);
	}

	public async Task<ReviewResponse> CreateReviewAsync(ReviewRequest request)
	{
		return await CreateAsync<Review, ReviewRequest, ReviewResponse>(
			request,
			req => {
				var review = ReviewMapper.ToEntity(req);
				review.ReviewerId = CurrentUserId;
				return review;
			},
			async (review, req) => {
				// Check if user can review this property
				var canReview = await CanUserReviewPropertyAsync(CurrentUserId, req.PropertyId);
				if (!canReview)
				{
					throw new UnauthorizedAccessException("User cannot review this property");
				}

				// For replies, inherit property from parent
				if (req.ParentReviewId.HasValue)
				{
					var parentReview = await Context.Reviews
						.FirstOrDefaultAsync(r => r.ReviewId == req.ParentReviewId.Value);

					if (parentReview == null)
					{
						throw new ArgumentException("Parent review not found");
					}

					review.PropertyId = parentReview.PropertyId;
				}
			},
			review => ReviewMapper.ToDto(review),
			"CreateReview"
		);
	}

	public async Task<ReviewResponse> UpdateReviewAsync(int reviewId, ReviewRequest request)
	{
		return await UpdateAsync<Review, ReviewRequest, ReviewResponse>(
			reviewId,
			request,
			q => q,  // No includes needed for update
			async review => review.ReviewerId == CurrentUserId, // Only review owner can update
			async (review, req) => {
				ReviewMapper.UpdateEntity(review, req);
			},
			review => ReviewMapper.ToDto(review),
			"UpdateReview"
		);
	}

	public async Task DeleteReviewAsync(int reviewId)
	{
		await DeleteAsync<Review>(
			reviewId,
			async review => {
				// Only review owner can delete
				if (review.ReviewerId != CurrentUserId)
				{
					throw new UnauthorizedAccessException("Only review owner can delete review");
				}

				// Delete child reviews first
				var replies = await Context.Reviews
					.Where(r => r.ParentReviewId == reviewId)
					.ToListAsync();
				
				if (replies.Any())
				{
					Context.Reviews.RemoveRange(replies);
				}

				return true;
			},
			"DeleteReview"
		);
	}

	public async Task<ReviewResponse> CreateReplyAsync(ReviewReplyRequest request)
	{
		return await CreateAsync<Review, ReviewReplyRequest, ReviewResponse>(
			request,
			req => {
				var reply = ReviewMapper.ToReplyEntity(req);
				reply.ReviewerId = CurrentUserId;
				return reply;
			},
			async (reply, req) => {
				// Check if user can reply to this review
				var canReply = await CanUserReplyToReviewAsync(CurrentUserId, req.ParentReviewId);
				if (!canReply)
				{
					throw new UnauthorizedAccessException("User cannot reply to this review");
				}

				// Get parent review to inherit PropertyId
				var parentReview = await Context.Reviews
					.FirstOrDefaultAsync(r => r.ReviewId == req.ParentReviewId);

				if (parentReview == null)
				{
					throw new ArgumentException("Parent review not found");
				}

				reply.PropertyId = parentReview.PropertyId;
			},
			reply => ReviewMapper.ToDto(reply),
			"CreateReviewReply"
		);
	}

	#endregion

	#region Review Queries

	public async Task<ReviewPagedResponse> GetReviewsAsync(ReviewFilterRequest filter)
	{
		var pagedResult = await GetPagedAsync<Review, ReviewResponse, ReviewFilterRequest>(
			filter,
			(query, search) => query
				.Include(r => r.Replies)
				.Include(r => r.Reviewer)
				.Include(r => r.Reviewee)
				.Include(r => r.Property),
			query => query, // Reviews are publicly viewable - no authorization filtering needed
			ApplyFilters,
			ApplySorting,
			review => ReviewMapper.ToDto(review),
			"GetReviews"
		);

		// Get additional statistics if property filter is applied
		ReviewStatisticsResponse? statistics = null;
		if (filter.PropertyId.HasValue)
		{
			statistics = await GetPropertyStatisticsAsync(filter.PropertyId.Value);
		}

		// Convert to ReviewPagedResponse with statistics
		var totalPages = (int)Math.Ceiling((double)pagedResult.TotalCount / pagedResult.PageSize);
		return new ReviewPagedResponse
		{
			Reviews = pagedResult.Items.ToList(),
			TotalCount = pagedResult.TotalCount,
			Page = pagedResult.Page,
			PageSize = pagedResult.PageSize,
			TotalPages = totalPages,
			HasNextPage = pagedResult.Page < totalPages,
			HasPreviousPage = pagedResult.Page > 1,
			Statistics = statistics
		};
	}

	private IQueryable<Review> ApplyFilters(IQueryable<Review> query, ReviewFilterRequest filter)
	{
		if (filter.PropertyId.HasValue)
			query = query.Where(r => r.PropertyId == filter.PropertyId.Value);

		if (filter.ReviewerId.HasValue)
			query = query.Where(r => r.ReviewerId == filter.ReviewerId.Value);

		if (filter.RevieweeId.HasValue)
			query = query.Where(r => r.RevieweeId == filter.RevieweeId.Value);

		if (filter.BookingId.HasValue)
			query = query.Where(r => r.BookingId == filter.BookingId.Value);

		if (filter.ParentReviewId.HasValue)
			query = query.Where(r => r.ParentReviewId == filter.ParentReviewId.Value);

		if (filter.MinRating.HasValue)
			query = query.Where(r => r.StarRating >= (decimal)filter.MinRating.Value);

		if (filter.MaxRating.HasValue)
			query = query.Where(r => r.StarRating <= (decimal)filter.MaxRating.Value);

		if (filter.StartDate.HasValue)
			query = query.Where(r => r.CreatedAt >= filter.StartDate.Value);

		if (filter.EndDate.HasValue)
			query = query.Where(r => r.CreatedAt <= filter.EndDate.Value);

		if (!string.IsNullOrEmpty(filter.SearchTerm))
		{
			var searchTerm = filter.SearchTerm.ToLower();
			query = query.Where(r => r.Description != null && r.Description.ToLower().Contains(searchTerm));
		}

		if (!filter.IncludeReplies.GetValueOrDefault())
			query = query.Where(r => !r.ParentReviewId.HasValue);

		return query;
	}

	private IQueryable<Review> ApplySorting(IQueryable<Review> query, ReviewFilterRequest filter)
	{
		return ApplySorting(query, filter.SortBy, filter.SortOrder);
	}

	public async Task<ReviewPagedResponse> GetPropertyReviewsAsync(int propertyId, int page = 1, int pageSize = 10, bool includeReplies = false)
	{
		var filter = new ReviewFilterRequest
		{
			PropertyId = propertyId,
			Page = page,
			PageSize = pageSize,
			IncludeReplies = includeReplies
			// Note: IsApproved property removed as it doesn't exist in Review entity
		};

		return await GetReviewsAsync(filter);
	}

	public async Task<ReviewPagedResponse> GetUserReviewsAsync(int userId, int page = 1, int pageSize = 10)
	{
		var filter = new ReviewFilterRequest
		{
			ReviewerId = userId,
			Page = page,
			PageSize = pageSize,
			IncludeReplies = false
		};

		return await GetReviewsAsync(filter);
	}

	public async Task<List<ReviewResponse>> GetReviewRepliesAsync(int parentReviewId)
	{
		try
		{
			var replies = await Context.Reviews
				.Where(r => r.ParentReviewId == parentReviewId)
				.Include(r => r.Reviewer)
				.Include(r => r.Reviewee)
				.Include(r => r.Property)
				.OrderBy(r => r.CreatedAt)
				.AsNoTracking()
				.ToListAsync();

			LogInfo("GetReviewReplies: Retrieved {Count} replies for review {ParentReviewId}", replies.Count, parentReviewId);
			return ReviewMapper.ToDto(replies);
		}
		catch (Exception ex)
		{
			LogError(ex, "Error getting replies for review {ParentReviewId}", parentReviewId);
			throw;
		}
	}

	public async Task<List<ReviewResponse>> GetRecentReviewsAsync(int count = 10)
	{
		try
		{
			var reviews = await Context.Reviews
				.Where(r => !r.ParentReviewId.HasValue)
				.Include(r => r.Reviewer)
				.Include(r => r.Reviewee)
				.Include(r => r.Property)
				.OrderByDescending(r => r.CreatedAt)
				.Take(count)
				.AsNoTracking()
				.ToListAsync();

			LogInfo("GetRecentReviews: Retrieved {Count} recent reviews", reviews.Count);
			return ReviewMapper.ToDto(reviews);
		}
		catch (Exception ex)
		{
			LogError(ex, "Error getting recent reviews");
			throw;
		}
	}

	#endregion

	#region Review Statistics

	public async Task<ReviewStatisticsResponse> GetPropertyStatisticsAsync(int propertyId)
	{
		try
		{
			var reviews = await Context.Reviews
				.Where(r => r.PropertyId == propertyId)
				.AsNoTracking()
				.ToListAsync();

			LogInfo("GetPropertyStatistics: Retrieved {Count} reviews for property {PropertyId}", reviews.Count, propertyId);
			return ReviewMapper.ToStatisticsDto(propertyId, reviews);
		}
		catch (Exception ex)
		{
			LogError(ex, "Error getting statistics for property {PropertyId}", propertyId);
			throw;
		}
	}

	public async Task<UserReviewSummaryResponse> GetUserSummaryAsync(int userId)
	{
		try
		{
			var userReviews = await Context.Reviews
				.Where(r => r.ReviewerId == userId)
				.AsNoTracking()
				.ToListAsync();

			LogInfo("GetUserSummary: Retrieved {Count} reviews for user {UserId}", userReviews.Count, userId);
			return ReviewMapper.ToUserSummaryDto(userId, userReviews);
		}
		catch (Exception ex)
		{
			LogError(ex, "Error getting summary for user {UserId}", userId);
			throw;
		}
	}

	public async Task<RatingBreakdownResponse> GetRatingBreakdownAsync(int propertyId)
	{
		try
		{
			var reviews = await Context.Reviews
				.Where(r => r.PropertyId == propertyId)
				.AsNoTracking()
				.ToListAsync();

			LogInfo("GetRatingBreakdown: Retrieved {Count} reviews for property {PropertyId}", reviews.Count, propertyId);
			return ReviewMapper.ToRatingBreakdownDto(propertyId, reviews);
		}
		catch (Exception ex)
		{
			LogError(ex, "Error getting rating breakdown for property {PropertyId}", propertyId);
			throw;
		}
	}



	#endregion



	#region Authorization Helpers

	public async Task<bool> CanUserReviewPropertyAsync(int userId, int propertyId)
	{
		try
		{
			// Check if user has a completed booking for this property
			var hasBooking = await Context.Bookings
				.AnyAsync(b => b.UserId == userId &&
							   b.PropertyId == propertyId &&
							   b.Status == BookingStatusEnum.Completed);

			// Check if user hasn't already reviewed this property
			var hasExistingReview = await Context.Reviews
				.AnyAsync(r => r.ReviewerId == userId &&
							   r.PropertyId == propertyId &&
							   !r.ParentReviewId.HasValue);

			// Check if user is the property owner (owners can't review their own properties)
			var property = await Context.Properties.FindAsync(propertyId);
			if (property?.OwnerId == userId)
				return false;

			var canReview = hasBooking && !hasExistingReview;
			LogInfo("CanUserReviewProperty: User {UserId} can review property {PropertyId}: {CanReview}", userId, propertyId, canReview);
			return canReview;
		}
		catch (Exception ex)
		{
			LogError(ex, "Error checking if user can review property {PropertyId}", propertyId);
			throw;
		}
	}

	public async Task<bool> CanUserReplyToReviewAsync(int userId, int reviewId)
	{
		try
		{
			var review = await Context.Reviews
				.Include(r => r.Property)
				.FirstOrDefaultAsync(r => r.ReviewId == reviewId);

			if (review == null || review.ParentReviewId.HasValue) // Can't reply to replies
			{
				return false;
			}

			// Property owner can reply to reviews on their property
			if (review.Property?.OwnerId == userId)
			{
				return true;
			}

			// User can reply to their own review (though this might be business rule dependent)
			var canReply = review.ReviewerId == userId;
			LogInfo("CanUserReplyToReview: User {UserId} can reply to review {ReviewId}: {CanReply}", userId, reviewId, canReply);
			return canReply;
		}
		catch (Exception ex)
		{
			LogError(ex, "Error checking reply permissions for user {UserId} and review {ReviewId}", userId, reviewId);
			return false;
		}
	}

	public async Task<bool> IsReviewOwnerAsync(int userId, int reviewId)
	{
		try
		{
			var review = await Context.Reviews.FindAsync(reviewId);
			var isOwner = review?.ReviewerId == userId;
			LogInfo("IsReviewOwner: User {UserId} owns review {ReviewId}: {IsOwner}", userId, reviewId, isOwner);
			return isOwner;
		}
		catch (Exception ex)
		{
			LogError(ex, "Error checking if user {UserId} is owner of review {ReviewId}", userId, reviewId);
			return false;
		}
	}

	#endregion





	#region Helper Methods

	private IQueryable<Review> ApplySorting(IQueryable<Review> query, string? sortBy, string? sortOrder)
	{
		var ascending = sortOrder?.ToUpper() == "ASC";

		return sortBy?.ToLower() switch
		{
			"rating" or "starrating" => ascending ? query.OrderBy(r => r.StarRating) : query.OrderByDescending(r => r.StarRating),
			"description" => ascending ? query.OrderBy(r => r.Description) : query.OrderByDescending(r => r.Description),
			"datecreated" or "createdat" or _ => ascending ? query.OrderBy(r => r.CreatedAt) : query.OrderByDescending(r => r.CreatedAt)
		};
	}

	#endregion
}
