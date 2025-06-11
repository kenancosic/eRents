using AutoMapper;
using eRents.Application.Shared;
using eRents.Domain.Models;
using eRents.Domain.Repositories;
using eRents.Shared.Services;
using eRents.Shared.Messaging;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Shared.SearchObjects;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;

namespace eRents.Application.Service.ReviewService
{
	public class ReviewService : BaseCRUDService<ReviewResponse, Review, ReviewSearchObject, ReviewInsertRequest, ReviewUpdateRequest>, IReviewService
	{
		private readonly IReviewRepository _reviewRepository;
		private readonly IRabbitMQService _rabbitMqService;

		public ReviewService(IReviewRepository reviewRepository, IRabbitMQService rabbitMQService, IMapper mapper)
				: base(reviewRepository, mapper)
		{
			_reviewRepository = reviewRepository;
			_rabbitMqService = rabbitMQService;

		}
		public override async Task<ReviewResponse> InsertAsync(ReviewInsertRequest request)
		{
			var reviewResponse = await base.InsertAsync(request);

			// Publish the notification to RabbitMQ
			var notificationMessage = new ReviewNotificationMessage
			{
				PropertyId = reviewResponse.PropertyId,
				ReviewId = reviewResponse.ReviewId,
				Message = "A new review has been posted."
			};
			await _rabbitMqService.PublishMessageAsync("reviewQueue", notificationMessage);

			return reviewResponse;
		}

		public async Task<decimal> GetAverageRatingAsync(int propertyId)
		{
			return await _reviewRepository.GetAverageRatingAsync(propertyId);
		}

		// 🆕 MIGRATED: Using Universal System with PropertyId filtering
		public async Task<IEnumerable<ReviewResponse>> GetReviewsForPropertyAsync(int propertyId)
		{
			var search = new ReviewSearchObject
			{
				PropertyId = propertyId,
				NoPaging = true // Get all reviews for this property
			};
			
			var pagedResult = await GetPagedAsync(search);
			return pagedResult.Items;
		}
		public async Task<bool> DeleteReviewAsync(int reviewId)
		{
			var review = await _repository.GetByIdAsync(reviewId);
			if (review == null)
			{
				return false; // Or throw an exception if that's the preferred behavior
			}
			await _repository.DeleteAsync(review);

			return true;
		}
		// 🆕 MIGRATED: Using Universal System with NoPaging option
		public override async Task<IEnumerable<ReviewResponse>> GetAsync(ReviewSearchObject search = null)
		{
			// Set NoPaging to true to get all results without pagination
			search ??= new ReviewSearchObject();
			search.NoPaging = true;
			
			// Use the Universal System GetPagedAsync method with NoPaging=true
			var pagedResult = await GetPagedAsync(search);
			
			// Return just the items (for backward compatibility)
			return pagedResult.Items;
		}

		// 🆕 NEW: Universal System implementation with user-scoped data access
		public override async Task<PagedList<ReviewResponse>> GetPagedAsync(ReviewSearchObject search = null)
		{
			// 1. Get user-scoped data (all reviews for now, add security filtering as needed)
			var userScopedReviews = await GetUserScopedReviewsAsync();
			
			// 2. Apply Universal System filtering and sorting
			var filteredReviews = ApplyUniversalFilters(userScopedReviews, search);
			var sortedReviews = ApplyUniversalSorting(filteredReviews, search);

			// 3. Apply pagination or return all results based on NoPaging
			search ??= new ReviewSearchObject();
			var page = search.PageNumber;
			var pageSize = search.PageSizeValue;
			var totalCount = sortedReviews.Count;
			
			var pagedReviews = sortedReviews
				.Skip((page - 1) * pageSize)
				.Take(pageSize)
				.ToList();

			// 4. Map to DTOs
			var dtoItems = _mapper.Map<List<ReviewResponse>>(pagedReviews);
			return new PagedList<ReviewResponse>(dtoItems, page, pageSize, totalCount);
		}

		/// <summary>
		/// Get reviews based on user permissions (for future role-based filtering)
		/// </summary>
		private async Task<List<Review>> GetUserScopedReviewsAsync()
		{
			// For now, return all reviews. Add user-specific filtering as needed.
			return await _repository.GetQueryable()
				.Include(r => r.Property)
				.Include(r => r.Reviewer)
				.Include(r => r.Reviewee)
				.Include(r => r.Booking)
				.Include(r => r.ParentReview)
				.Include(r => r.Replies)
				.Include(r => r.Images)
				.ToListAsync();
		}

		// 🆕 UNIVERSAL SYSTEM: Custom filters for navigation properties only
		protected override IQueryable<Review> ApplyCustomFilters(IQueryable<Review> query, ReviewSearchObject search)
		{
			if (search == null) return query;

			// ✅ AUTOMATIC: PropertyId, RevieweeId, ReviewerId, BookingId, ParentReviewId, Description,
			//               MinStarRating/MaxStarRating, MinDateCreated/MaxDateCreated, ReviewType
			//               All handled automatically by Universal System! 🎉

			// Handle SearchTerm for navigation properties (can't be automated)
			if (!string.IsNullOrEmpty(search.SearchTerm))
			{
				var searchTerm = search.SearchTerm.ToLower();
				query = query.Where(r => 
					(r.Property.Name != null && r.Property.Name.ToLower().Contains(searchTerm)) ||
					(r.Reviewer.FirstName != null && r.Reviewer.FirstName.ToLower().Contains(searchTerm)) ||
					(r.Reviewer.LastName != null && r.Reviewer.LastName.ToLower().Contains(searchTerm)) ||
					(r.Reviewee.FirstName != null && r.Reviewee.FirstName.ToLower().Contains(searchTerm)) ||
					(r.Reviewee.LastName != null && r.Reviewee.LastName.ToLower().Contains(searchTerm)) ||
					r.ReviewId.ToString().Contains(searchTerm));
			}

			// Navigation property: Property name filtering
			if (!string.IsNullOrEmpty(search.PropertyName))
				query = query.Where(r => r.Property.Name.Contains(search.PropertyName));

			// Navigation property: Reviewer name filtering
			if (!string.IsNullOrEmpty(search.ReviewerName))
			{
				var nameParts = search.ReviewerName.ToLower().Split(' ', StringSplitOptions.RemoveEmptyEntries);
				foreach (var part in nameParts)
				 {
          query = query.Where(r => r.Reviewer != null && 
                (r.Reviewer.FirstName.ToLower().Contains(part) || r.Reviewer.LastName.ToLower().Contains(part)));
        }
			}

			// Navigation property: Reviewee name filtering
			if (!string.IsNullOrEmpty(search.RevieweeName))
			{
				var nameParts = search.RevieweeName.ToLower().Split(' ', StringSplitOptions.RemoveEmptyEntries);
				foreach (var part in nameParts)
        {
            query = query.Where(r => r.Reviewee != null && 
                (r.Reviewee.FirstName.ToLower().Contains(part) || r.Reviewee.LastName.ToLower().Contains(part)));
        }
			}

			// Complex filter: Has replies
			if (search.HasReplies.HasValue)
			{
				if (search.HasReplies.Value)
					query = query.Where(r => r.Replies.Any());
				else
					query = query.Where(r => !r.Replies.Any());
			}

			// Complex filter: Is original review (not a reply)
			if (search.IsOriginalReview.HasValue)
			{
				if (search.IsOriginalReview.Value)
					query = query.Where(r => r.ParentReviewId == null);
				else
					query = query.Where(r => r.ParentReviewId != null);
			}

			// DEPRECATED: Backward compatibility support
			#pragma warning disable CS0618 // Type or member is obsolete
			if (search.MinRating.HasValue)
				query = query.Where(r => r.StarRating >= search.MinRating);

			if (search.MaxRating.HasValue)
				query = query.Where(r => r.StarRating <= search.MaxRating);

			if (search.TenantId.HasValue)
				query = query.Where(r => r.RevieweeId == search.TenantId);
			#pragma warning restore CS0618

			return query;
		}

		// 🆕 UNIVERSAL SYSTEM: Custom sorting for navigation properties only
		protected override List<Review> ApplyCustomSorting(List<Review> entities, ReviewSearchObject search)
		{
			if (search?.SortBy == null)
				return ApplyDefaultSorting(entities);

			// ✅ AUTOMATIC: "StarRating", "DateCreated", "PropertyId", "ReviewType" work automatically!
			// Handle only navigation properties that can't be automated:
			return search.SortBy.ToLower() switch
			{
				"propertyname" => search.SortDescending
            ? entities.OrderByDescending(r => r.Property?.Name ?? "").ToList()
            : entities.OrderBy(r => r.Property?.Name ?? "").ToList(),
        "reviewername" => search.SortDescending
            ? entities.OrderByDescending(r => $"{r.Reviewer?.FirstName} {r.Reviewer?.LastName}".Trim()).ToList()
            : entities.OrderBy(r => $"{r.Reviewer?.FirstName} {r.Reviewer?.LastName}".Trim()).ToList(),
        "revieweename" => search.SortDescending
            ? entities.OrderByDescending(r => $"{r.Reviewee?.FirstName} {r.Reviewee?.LastName}".Trim()).ToList()
            : entities.OrderBy(r => $"{r.Reviewee?.FirstName} {r.Reviewee?.LastName}".Trim()).ToList(),
				// DEPRECATED: Backward compatibility
				"date" => search.SortDescending
					? entities.OrderByDescending(r => r.DateCreated).ToList()
					: entities.OrderBy(r => r.DateCreated).ToList(),
				"rating" => search.SortDescending
					? entities.OrderByDescending(r => r.StarRating ?? 0).ToList()
					: entities.OrderBy(r => r.StarRating ?? 0).ToList(),
				_ => base.ApplyCustomSorting(entities, search) // Use universal sorting
			};
		}

		private byte[] ConvertToBytes(IFormFile imageFile)
		{
			using (var ms = new MemoryStream())
			{
				imageFile.CopyTo(ms);
				return ms.ToArray();
			}
		}

	}
}