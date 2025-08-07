using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using eRents.Domain.Models;
using eRents.Domain.Models.Enums;
using eRents.Features.Core.Services;
using eRents.Features.ReviewManagement.Models;
using AutoMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace eRents.Features.ReviewManagement.Services;

public class ReviewService : BaseCrudService<Review, ReviewRequest, ReviewResponse, ReviewSearch>
{
	public ReviewService(
			ERentsContext context,
			IMapper mapper,
			ILogger<ReviewService> logger)
			: base(context, mapper, logger)
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

	// Remove 'override' to align with current BaseCrudService contract if it does not declare virtuals.
	public async Task<ReviewResponse> CreateAsync(ReviewRequest request, CancellationToken cancellationToken = default)
	{
		// Enforce thread/parent existence if reply
		if (request.ParentReviewId.HasValue)
		{
		    var parentExists = await Context.Set<Review>()
		            .AsNoTracking()
		            .AnyAsync(r => r.ReviewId == request.ParentReviewId.Value, cancellationToken);
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

		// Replies do not require StarRating; original reviews may omit rating as per scope
		return await base.CreateAsync(request);
	}

	// Remove 'override' similarly here.
	public async Task<ReviewResponse> UpdateAsync(int id, ReviewRequest request, CancellationToken cancellationToken = default)
	{
		// Validate parent existence if reply
		if (request.ParentReviewId.HasValue)
		{
			var parentExists = await Context.Set<Review>()
			        .AsNoTracking()
			        .AnyAsync(r => r.ReviewId == request.ParentReviewId.Value, cancellationToken);
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

		return await base.UpdateAsync(id, request);
	}
}