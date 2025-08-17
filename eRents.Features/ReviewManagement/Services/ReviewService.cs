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
using eRents.Features.Core;
using eRents.Domain.Shared.Interfaces;

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

		// Desktop owner/landlord filtering
		if (CurrentUser?.IsDesktop == true &&
		    !string.IsNullOrWhiteSpace(CurrentUser.UserRole) &&
		    (string.Equals(CurrentUser.UserRole, "Owner", StringComparison.OrdinalIgnoreCase) ||
		     string.Equals(CurrentUser.UserRole, "Landlord", StringComparison.OrdinalIgnoreCase)))
		{
			var ownerId = CurrentUser.GetUserIdAsInt();
			if (ownerId.HasValue)
			{
				query = query.Where(r => 
					r.Property != null && r.Property.OwnerId == ownerId.Value ||
					r.Booking != null && r.Booking.Property != null && r.Booking.Property.OwnerId == ownerId.Value);
			}
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
		// Enforce thread/parent existence if reply
		if (request.ParentReviewId.HasValue)
		{
		    var parentExists = await Context.Set<Review>()
		            .AsNoTracking()
		            .AnyAsync(r => r.ReviewId == request.ParentReviewId.Value);
		    if (!parentExists)
		        throw new KeyNotFoundException($"Parent review {request.ParentReviewId.Value} not found.");
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

		// Ownership enforcement for Desktop owners/landlords
		if (CurrentUser?.IsDesktop == true &&
		    !string.IsNullOrWhiteSpace(CurrentUser.UserRole) &&
		    (string.Equals(CurrentUser.UserRole, "Owner", StringComparison.OrdinalIgnoreCase) ||
		     string.Equals(CurrentUser.UserRole, "Landlord", StringComparison.OrdinalIgnoreCase)))
		{
			var ownerId = CurrentUser.GetUserIdAsInt();
			if (ownerId.HasValue)
			{
				if (request.PropertyId.HasValue)
				{
					var prop = await Context.Set<Property>()
						.AsNoTracking()
						.FirstOrDefaultAsync(p => p.PropertyId == request.PropertyId.Value);
					if (prop == null || prop.OwnerId != ownerId.Value)
						throw new KeyNotFoundException("Property not found");
				}
				else if (request.BookingId.HasValue)
				{
					var booking = await Context.Set<Booking>()
						.AsNoTracking()
						.Include(b => b.Property)
						.FirstOrDefaultAsync(b => b.BookingId == request.BookingId.Value);
					if (booking == null || booking.Property == null || booking.Property.OwnerId != ownerId.Value)
						throw new KeyNotFoundException("Booking not found");
				}
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

		// Ownership enforcement for Desktop owners/landlords
		if (CurrentUser?.IsDesktop == true &&
		    !string.IsNullOrWhiteSpace(CurrentUser.UserRole) &&
		    (string.Equals(CurrentUser.UserRole, "Owner", StringComparison.OrdinalIgnoreCase) ||
		     string.Equals(CurrentUser.UserRole, "Landlord", StringComparison.OrdinalIgnoreCase)))
		{
			var ownerId = CurrentUser.GetUserIdAsInt();
			if (ownerId.HasValue)
			{
				var propId = request.PropertyId ?? entity.PropertyId;
				if (propId.HasValue)
				{
					var prop = await Context.Set<Property>()
						.AsNoTracking()
						.FirstOrDefaultAsync(p => p.PropertyId == propId.Value);
					if (prop == null || prop.OwnerId != ownerId.Value)
						throw new KeyNotFoundException($"Review with id {entity.ReviewId} not found");
				}
				else if (request.BookingId.HasValue || entity.BookingId.HasValue)
				{
					var bid = request.BookingId ?? entity.BookingId!.Value;
					var booking = await Context.Set<Booking>()
						.AsNoTracking()
						.Include(b => b.Property)
						.FirstOrDefaultAsync(b => b.BookingId == bid);
					if (booking == null || booking.Property == null || booking.Property.OwnerId != ownerId.Value)
						throw new KeyNotFoundException($"Review with id {entity.ReviewId} not found");
				}
			}
		}
	}

    public override async Task<ReviewResponse> GetByIdAsync(int id)
    {
        var entity = await Context.Set<Review>()
            .Include(r => r.Property)
            .Include(r => r.Booking).ThenInclude(b => b!.Property)
            .FirstOrDefaultAsync(r => r.ReviewId == id);

        if (entity == null)
            throw new KeyNotFoundException($"Review with id {id} not found");

        if (CurrentUser?.IsDesktop == true &&
            !string.IsNullOrWhiteSpace(CurrentUser.UserRole) &&
            (string.Equals(CurrentUser.UserRole, "Owner", StringComparison.OrdinalIgnoreCase) ||
             string.Equals(CurrentUser.UserRole, "Landlord", StringComparison.OrdinalIgnoreCase)))
        {
            var ownerId = CurrentUser.GetUserIdAsInt();
            var owned = (entity.Property?.OwnerId == ownerId)
                        || (entity.Booking?.Property?.OwnerId == ownerId);
            if (!ownerId.HasValue || !owned)
                throw new KeyNotFoundException($"Review with id {id} not found");
        }

        return Mapper.Map<ReviewResponse>(entity);
    }
}