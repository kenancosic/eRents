using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using eRents.Domain.Models;
using eRents.Features.ReviewManagement.DTOs;
using eRents.Features.ReviewManagement.Mappers;
using eRents.Domain.Shared.Interfaces;

namespace eRents.Features.ReviewManagement.Services;

/// <summary>
/// Review management service implementation
/// Following modular architecture principles using ERentsContext directly
/// </summary>
public class ReviewService : IReviewService
{
	private readonly ERentsContext _context;
	private readonly ICurrentUserService _currentUserService;
	private readonly ILogger<ReviewService> _logger;

	public ReviewService(
			ERentsContext context,
			ICurrentUserService currentUserService,
			ILogger<ReviewService> logger)
	{
		_context = context;
		_currentUserService = currentUserService;
		_logger = logger;
	}

	#region Core Review Operations

	public async Task<ReviewResponse?> GetReviewByIdAsync(int reviewId)
	{
		try
		{
			var review = await _context.Reviews
					.Include(r => r.Replies)
					.Include(r => r.Reviewer)
					.Include(r => r.Reviewee)
					.Include(r => r.Property)
					.FirstOrDefaultAsync(r => r.ReviewId == reviewId);

			return review != null ? ReviewMapper.ToDto(review) : null;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error getting review {ReviewId}", reviewId);
			throw;
		}
	}

	public async Task<ReviewResponse> CreateReviewAsync(ReviewRequest request)
	{
		try
		{
			var currentUserId = _currentUserService.GetUserIdAsInt() ?? throw new UnauthorizedAccessException("User not authenticated");

			// Check if user can review this property
			var canReview = await CanUserReviewPropertyAsync(currentUserId, request.PropertyId);
			if (!canReview)
			{
				throw new UnauthorizedAccessException("User cannot review this property");
			}

			var review = ReviewMapper.ToEntity(request);
			review.ReviewerId = currentUserId;

			// For replies, inherit property from parent and don't require property check
			if (request.ParentReviewId.HasValue)
			{
				var parentReview = await _context.Reviews
						.FirstOrDefaultAsync(r => r.ReviewId == request.ParentReviewId.Value);

				if (parentReview == null)
				{
					throw new ArgumentException("Parent review not found");
				}

				review.PropertyId = parentReview.PropertyId;
			}

			_context.Reviews.Add(review);
			await _context.SaveChangesAsync();

			_logger.LogInformation("Review created: {ReviewId} by user {UserId} for property {PropertyId}",
					review.ReviewId, currentUserId, review.PropertyId);

			return ReviewMapper.ToDto(review);
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error creating review for property {PropertyId}", request.PropertyId);
			throw;
		}
	}

	public async Task<ReviewResponse> UpdateReviewAsync(int reviewId, ReviewRequest request)
	{
		try
		{
			var currentUserId = _currentUserService.GetUserIdAsInt() ?? throw new UnauthorizedAccessException("User not authenticated");
			var review = await _context.Reviews.FindAsync(reviewId);

			if (review == null)
			{
				throw new ArgumentException("Review not found");
			}

			// Only review owner can update
			if (review.ReviewerId != currentUserId)
			{
				throw new UnauthorizedAccessException("Only review owner can update");
			}

			ReviewMapper.UpdateEntity(review, request);

			await _context.SaveChangesAsync();

			_logger.LogInformation("Review updated: {ReviewId} by user {UserId}", reviewId, currentUserId);

			return ReviewMapper.ToDto(review);
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error updating review {ReviewId}", reviewId);
			throw;
		}
	}

	public async Task<bool> DeleteReviewAsync(int reviewId)
	{
		try
		{
			var currentUserId = _currentUserService.GetUserIdAsInt() ?? throw new UnauthorizedAccessException("User not authenticated");
			var review = await _context.Reviews
					.Include(r => r.Replies)
					.FirstOrDefaultAsync(r => r.ReviewId == reviewId);

			if (review == null)
			{
				return false;
			}

			// Only review owner can delete
			if (review.ReviewerId != currentUserId)
			{
				throw new UnauthorizedAccessException("Only review owner can delete review");
			}

			// Delete child reviews first
			if (review.Replies?.Any() == true)
			{
				_context.Reviews.RemoveRange(review.Replies);
			}

			_context.Reviews.Remove(review);
			await _context.SaveChangesAsync();

			_logger.LogInformation("Review deleted: {ReviewId} by user {UserId}", reviewId, currentUserId);

			return true;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error deleting review {ReviewId}", reviewId);
			throw;
		}
	}

	public async Task<ReviewResponse> CreateReplyAsync(ReviewReplyRequest request)
	{
		try
		{
			var currentUserId = _currentUserService.GetUserIdAsInt() ?? throw new UnauthorizedAccessException("User not authenticated");

			// Check if user can reply to this review
			var canReply = await CanUserReplyToReviewAsync(currentUserId, request.ParentReviewId);
			if (!canReply)
			{
				throw new UnauthorizedAccessException("User cannot reply to this review");
			}

			var reply = ReviewMapper.ToReplyEntity(request);
			reply.ReviewerId = currentUserId;

			// Get parent review to inherit PropertyId
			var parentReview = await _context.Reviews
					.FirstOrDefaultAsync(r => r.ReviewId == request.ParentReviewId);

			if (parentReview == null)
			{
				throw new ArgumentException("Parent review not found");
			}

			reply.PropertyId = parentReview.PropertyId;

			_context.Reviews.Add(reply);
			await _context.SaveChangesAsync();

			_logger.LogInformation("Review reply created: {ReviewId} by user {UserId} for parent {ParentReviewId}",
					reply.ReviewId, currentUserId, request.ParentReviewId);

			return ReviewMapper.ToDto(reply);
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error creating reply to review {ParentReviewId}", request.ParentReviewId);
			throw;
		}
	}

	#endregion

	#region Review Queries

	public async Task<ReviewPagedResponse> GetReviewsAsync(ReviewFilterRequest filter)
	{
		try
		{
			var query = _context.Reviews
					.Include(r => r.Replies)
					.Include(r => r.Reviewer)
					.Include(r => r.Reviewee)
					.Include(r => r.Property)
					.AsQueryable();

			// Apply filters
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

			// Apply sorting
			query = ApplySorting(query, filter.SortBy, filter.SortOrder);

			var totalCount = await query.CountAsync();
			var reviews = await query
					.Skip((filter.Page - 1) * filter.PageSize)
					.Take(filter.PageSize)
					.ToListAsync();

			// Get statistics if property filter is applied
			ReviewStatisticsResponse? statistics = null;
			if (filter.PropertyId.HasValue)
			{
				statistics = await GetPropertyStatisticsAsync(filter.PropertyId.Value);
			}

			return ReviewMapper.ToPagedResponse(reviews, totalCount, filter.Page, filter.PageSize, statistics);
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error getting reviews with filter");
			throw;
		}
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
			var replies = await _context.Reviews
					.Where(r => r.ParentReviewId == parentReviewId)
					.Include(r => r.Reviewer)
					.Include(r => r.Reviewee)
					.Include(r => r.Property)
					.OrderBy(r => r.CreatedAt)
					.ToListAsync();

			return ReviewMapper.ToDto(replies);
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error getting replies for review {ParentReviewId}", parentReviewId);
			throw;
		}
	}

	public async Task<List<ReviewResponse>> GetRecentReviewsAsync(int count = 10)
	{
		try
		{
			var reviews = await _context.Reviews
					.Where(r => !r.ParentReviewId.HasValue)
					.Include(r => r.Reviewer)
					.Include(r => r.Reviewee)
					.Include(r => r.Property)
					.OrderByDescending(r => r.CreatedAt)
					.Take(count)
					.ToListAsync();

			return ReviewMapper.ToDto(reviews);
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error getting recent reviews");
			throw;
		}
	}

	#endregion

	#region Review Statistics

	public async Task<ReviewStatisticsResponse> GetPropertyStatisticsAsync(int propertyId)
	{
		try
		{
			var reviews = await _context.Reviews
					.Where(r => r.PropertyId == propertyId)
					.ToListAsync();

			return ReviewMapper.ToStatisticsDto(propertyId, reviews);
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error getting statistics for property {PropertyId}", propertyId);
			throw;
		}
	}

	public async Task<UserReviewSummaryResponse> GetUserSummaryAsync(int userId)
	{
		try
		{
			var userReviews = await _context.Reviews
					.Where(r => r.ReviewerId == userId)
					.ToListAsync();

			return ReviewMapper.ToUserSummaryDto(userId, userReviews);
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error getting summary for user {UserId}", userId);
			throw;
		}
	}

	public async Task<RatingBreakdownResponse> GetRatingBreakdownAsync(int propertyId)
	{
		try
		{
			var reviews = await _context.Reviews
					.Where(r => r.PropertyId == propertyId)
					.ToListAsync();

			return ReviewMapper.ToRatingBreakdownDto(propertyId, reviews);
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error getting rating breakdown for property {PropertyId}", propertyId);
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
			var hasBooking = await _context.Bookings
					.AnyAsync(b => b.UserId == userId &&
											 b.PropertyId == propertyId &&
											 b.BookingStatus.StatusName == "Completed");

			// Check if user hasn't already reviewed this property
			var hasExistingReview = await _context.Reviews
					.AnyAsync(r => r.ReviewerId == userId &&
											 r.PropertyId == propertyId &&
											 !r.ParentReviewId.HasValue);

			// Check if user is the property owner (owners can't review their own properties)
			var property = await _context.Properties.FindAsync(propertyId);
			if (property?.OwnerId == userId)
				return false;

			return hasBooking && !hasExistingReview;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error checking if user can review property {PropertyId}", propertyId);
			throw;
		}
	}

	public async Task<bool> CanUserReplyToReviewAsync(int userId, int reviewId)
	{
		try
		{
			var review = await _context.Reviews
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
			return review.ReviewerId == userId;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error checking reply permissions for user {UserId} and review {ReviewId}", userId, reviewId);
			return false;
		}
	}



	public async Task<bool> IsReviewOwnerAsync(int userId, int reviewId)
	{
		try
		{
			var review = await _context.Reviews.FindAsync(reviewId);
			return review?.ReviewerId == userId;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error checking if user {UserId} is owner of review {ReviewId}", userId, reviewId);
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
