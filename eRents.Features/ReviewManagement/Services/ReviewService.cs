using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using eRents.Domain.Models;
using eRents.Domain.Models.Enums;
using eRents.Features.ReviewManagement.Models;
using AutoMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using eRents.Features.Core.Extensions;
using eRents.Domain.Shared.Interfaces;
using eRents.Features.Core;

namespace eRents.Features.ReviewManagement.Services;

public class ReviewService : BaseCrudService<Review, ReviewRequest, ReviewResponse, ReviewSearch>
{
	public ReviewService(
			ERentsContext context,
			IMapper mapper,
			ILogger<ReviewService> logger,
			ICurrentUserService? currentUserService = null)
			: base(context, mapper, logger, currentUserService)
	{
	}

	protected override IQueryable<Review> AddIncludes(IQueryable<Review> query)
	{
		// Include Reviewer to populate ReviewerFirstName/LastName in response
		return query.Include(r => r.Reviewer);
	}

	protected override IQueryable<Review> AddFilter(IQueryable<Review> query, ReviewSearch search)
	{
		if (search.PropertyId.HasValue)
		{
			var id = search.PropertyId.Value;
			query = query.Where(x => x.PropertyId == id);
		}

		if (search.ReviewerId.HasValue)
		{
			var id = search.ReviewerId.Value;
			query = query.Where(x => x.ReviewerId == id);
		}

		if (search.RevieweeId.HasValue)
		{
			var id = search.RevieweeId.Value;
			query = query.Where(x => x.RevieweeId == id);
		}

		if (search.ReviewType.HasValue)
		{
			var t = search.ReviewType.Value;
			query = query.Where(x => x.ReviewType == t);
		}

		if (search.BookingId.HasValue)
		{
			var id = search.BookingId.Value;
			query = query.Where(x => x.BookingId == id);
		}

		if (search.ParentReviewId.HasValue)
		{
			var id = search.ParentReviewId.Value;
			query = query.Where(x => x.ParentReviewId == id);
		}

		if (search.StarRatingMin.HasValue)
		{
			var min = search.StarRatingMin.Value;
			query = query.Where(x => x.StarRating != null && x.StarRating >= min);
		}

		if (search.StarRatingMax.HasValue)
		{
			var max = search.StarRatingMax.Value;
			query = query.Where(x => x.StarRating != null && x.StarRating <= max);
		}

		if (search.CreatedFrom.HasValue)
		{
			var from = search.CreatedFrom.Value;
			query = query.Where(x => x.CreatedAt >= from);
		}

		if (search.CreatedTo.HasValue)
		{
			var to = search.CreatedTo.Value;
			query = query.Where(x => x.CreatedAt <= to);
		}

		// Desktop owner/landlord filtering - simplified using extension method
		var ownerId = CurrentUser?.GetDesktopOwnerId();
		if (ownerId.HasValue)
		{
			query = query.Where(r =>
					r.Property != null && r.Property.OwnerId == ownerId.Value ||
					r.Booking != null && r.Booking.Property != null && r.Booking.Property.OwnerId == ownerId.Value);
		}

		return query;
	}

	protected override IQueryable<Review> AddSorting(IQueryable<Review> query, ReviewSearch search)
	{
		var sortBy = (search.SortBy ?? string.Empty).Trim().ToLower();
		var sortDir = (search.SortDirection ?? "asc").Trim().ToLower();
		var desc = sortDir == "desc";

		query = sortBy switch
		{
			"createdat" => desc ? query.OrderByDescending(x => x.CreatedAt) : query.OrderBy(x => x.CreatedAt),
			"updatedat" => desc ? query.OrderByDescending(x => x.UpdatedAt) : query.OrderBy(x => x.UpdatedAt),
			"starrating" => desc ? query.OrderByDescending(x => x.StarRating) : query.OrderBy(x => x.StarRating),
			_ => desc ? query.OrderByDescending(x => x.ReviewId) : query.OrderBy(x => x.ReviewId)
		};

		return query;
	}

	protected override async Task BeforeCreateAsync(Review entity, ReviewRequest request)
	{
		// Mobile-only restriction: owners cannot review their own properties from mobile client
		if (CurrentUser?.IsDesktop != true && request.PropertyId.HasValue)
		{
			var currentUserId = CurrentUser?.GetUserIdAsInt();
			if (currentUserId.HasValue)
			{
				var prop = await Context.Set<Property>()
						.AsNoTracking()
						.Select(p => new { p.PropertyId, p.OwnerId })
						.FirstOrDefaultAsync(p => p.PropertyId == request.PropertyId.Value);

				if (prop != null && prop.OwnerId == currentUserId.Value)
				{
					throw new InvalidOperationException("Owners cannot review their own properties.");
				}
			}
		}

		// Enforce thread/parent existence if reply and inherit propertyId/bookingId
		if (request.ParentReviewId.HasValue)
		{
			var parentReview = await Context.Set<Review>()
							.AsNoTracking()
							.FirstOrDefaultAsync(r => r.ReviewId == request.ParentReviewId.Value);
			if (parentReview == null)
				throw new KeyNotFoundException($"Parent review {request.ParentReviewId.Value} not found.");

			// Inherit propertyId and bookingId from parent review for replies
			if (!request.PropertyId.HasValue && parentReview.PropertyId.HasValue)
			{
				request.PropertyId = parentReview.PropertyId;
				entity.PropertyId = parentReview.PropertyId;
			}
			if (!request.BookingId.HasValue && parentReview.BookingId.HasValue)
			{
				request.BookingId = parentReview.BookingId;
				entity.BookingId = parentReview.BookingId;
			}

			// Set the reviewer to current user for replies
			var currentUserId = CurrentUser?.GetUserIdAsInt();
			if (currentUserId.HasValue)
			{
				entity.ReviewerId = currentUserId.Value;
			}
		}

		// Enforce ReviewType semantics for original reviews
		if (!request.ParentReviewId.HasValue)
		{
			if (request.ReviewType == ReviewType.PropertyReview)
			{
				if (!request.PropertyId.HasValue)
					throw new ArgumentException("PropertyId is required for PropertyReview.");
			}
			else if (request.ReviewType == ReviewType.TenantReview)
			{
				if (!request.RevieweeId.HasValue)
					throw new ArgumentException("RevieweeId is required for TenantReview.");
			}
		}

		// Ownership enforcement for Desktop owners/landlords - simplified
		if (CurrentUser.IsDesktopOwnerOrLandlord())
		{
			if (request.PropertyId.HasValue)
			{
				await ValidatePropertyOwnershipOrThrowAsync(request.PropertyId.Value, 0);
			}
			else if (request.BookingId.HasValue)
			{
				var booking = await Context.Set<Booking>()
						.AsNoTracking()
						.Include(b => b.Property)
						.FirstOrDefaultAsync(b => b.BookingId == request.BookingId.Value);
				if (booking?.Property == null)
					throw new KeyNotFoundException("Booking not found");
				await ValidatePropertyOwnershipOrThrowAsync(booking.Property.PropertyId, 0);
			}
		}
	}

	protected override async Task BeforeUpdateAsync(Review entity, ReviewRequest request)
	{
		// Validate parent existence if reply
		if (request.ParentReviewId.HasValue)
		{
			var parentExists = await Context.Set<Review>()
							.AsNoTracking()
							.AnyAsync(r => r.ReviewId == request.ParentReviewId.Value);
			if (!parentExists)
				throw new KeyNotFoundException($"Parent review {request.ParentReviewId.Value} not found.");
		}

		// Enforce ReviewType semantics for originals
		if (!request.ParentReviewId.HasValue)
		{
			if (request.ReviewType == ReviewType.PropertyReview)
			{
				if (!request.PropertyId.HasValue)
					throw new ArgumentException("PropertyId is required for PropertyReview.");
			}
			else if (request.ReviewType == ReviewType.TenantReview)
			{
				if (!request.RevieweeId.HasValue)
					throw new ArgumentException("RevieweeId is required for TenantReview.");
			}
		}

		// Ownership enforcement for Desktop owners/landlords - simplified
		if (CurrentUser.IsDesktopOwnerOrLandlord())
		{
			var propId = request.PropertyId ?? entity.PropertyId;
			if (propId.HasValue)
			{
				await ValidatePropertyOwnershipOrThrowAsync(propId.Value, entity.ReviewId);
			}
			else if (request.BookingId.HasValue || entity.BookingId.HasValue)
			{
				var bid = request.BookingId ?? entity.BookingId!.Value;
				var booking = await Context.Set<Booking>()
						.AsNoTracking()
						.Include(b => b.Property)
						.FirstOrDefaultAsync(b => b.BookingId == bid);
				if (booking?.Property == null || booking.Property.OwnerId != CurrentUser?.GetUserIdAsInt())
					throw new KeyNotFoundException($"Review with id {entity.ReviewId} not found");
			}
		}
	}

	public override async Task<ReviewResponse> GetByIdAsync(int id)
	{
		var entity = await Context.Set<Review>()
				.Include(r => r.Property)
				.Include(r => r.Reviewer)
				.Include(r => r.Booking).ThenInclude(b => b!.Property)
				.FirstOrDefaultAsync(r => r.ReviewId == id);

		if (entity == null)
			throw new KeyNotFoundException($"Review with id {id} not found");

		// Ownership enforcement for Desktop owners/landlords - simplified
		if (CurrentUser.IsDesktopOwnerOrLandlord())
		{
			var propId = entity.PropertyId ?? entity.Booking?.PropertyId;
			if (propId.HasValue)
			{
				await ValidatePropertyOwnershipOrThrowAsync(propId.Value, entity.ReviewId);
			}
		}

		return Mapper.Map<ReviewResponse>(entity);
	}
}