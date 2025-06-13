using eRents.Domain.Models;
using eRents.Domain.Shared;
using eRents.Shared.Enums;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using eRents.Shared.SearchObjects;
using System.Linq;
using System;
using System.Threading.Tasks;
using System.Collections.Generic;

namespace eRents.Domain.Repositories
{
	public class ReviewRepository : BaseRepository<Review>, IReviewRepository
	{
		public ReviewRepository(ERentsContext context) : base(context) { }

		protected override IQueryable<Review> ApplyIncludes<TSearch>(IQueryable<Review> query, TSearch search)
		{
			return query
				.Include(r => r.Property)
				.Include(r => r.Reviewer)
				.Include(r => r.Reviewee)
				.Include(r => r.Booking)
				.Include(r => r.ParentReview)
				.Include(r => r.Replies)
				.Include(r => r.Images);
		}

		protected override IQueryable<Review> ApplyFilters<TSearch>(IQueryable<Review> query, TSearch search)
		{
			query = base.ApplyFilters(query, search);
			if (search is not ReviewSearchObject reviewSearch) return query;

			if (reviewSearch.PropertyId.HasValue)
				query = query.Where(r => r.PropertyId == reviewSearch.PropertyId.Value);

			if (!string.IsNullOrEmpty(reviewSearch.PropertyName))
				query = query.Where(r => r.Property.Name.Contains(reviewSearch.PropertyName));
			
			if (reviewSearch.HasReplies.HasValue)
			{
				if (reviewSearch.HasReplies.Value)
					query = query.Where(r => r.Replies.Any());
				else
					query = query.Where(r => !r.Replies.Any());
			}

			if (reviewSearch.IsOriginalReview.HasValue)
			{
				if (reviewSearch.IsOriginalReview.Value)
					query = query.Where(r => r.ParentReviewId == null);
				else
					query = query.Where(r => r.ParentReviewId != null);
			}

			return query;
		}

		protected override string[] GetSearchableProperties()
		{
			return new string[]
			{
				"Property.Name",
				"Reviewer.FirstName",
				"Reviewer.LastName",
				"Reviewee.FirstName",
				"Reviewee.LastName",
				"Description"
			};
		}

		protected override IQueryable<Review>? ApplyCustomOrdering<TSearch>(IQueryable<Review> query, string sortBy, bool descending)
		{
			if (sortBy.Equals("ReviewerName", StringComparison.OrdinalIgnoreCase))
			{
				var orderedQuery = descending 
					? query.OrderByDescending(r => r.Reviewer.FirstName).ThenByDescending(r => r.Reviewer.LastName) 
					: query.OrderBy(r => r.Reviewer.FirstName).ThenBy(r => r.Reviewer.LastName);
				return orderedQuery;
			}
			if (sortBy.Equals("RevieweeName", StringComparison.OrdinalIgnoreCase))
			{
				var orderedQuery = descending 
					? query.OrderByDescending(r => r.Reviewee.FirstName).ThenByDescending(r => r.Reviewee.LastName) 
					: query.OrderBy(r => r.Reviewee.FirstName).ThenBy(r => r.Reviewee.LastName);
				return orderedQuery;
			}
			
			return base.ApplyCustomOrdering<TSearch>(query, sortBy, descending);
		}

		public async Task<decimal> GetAverageRatingAsync(int propertyId)
		{
			return await _context.Reviews
							.Where(r => r.PropertyId == propertyId)
							.AverageAsync(r => (decimal?)r.StarRating) ?? 0;
		}

		public async Task<IEnumerable<Review>> GetReviewsByPropertyAsync(int propertyId)
		{
			return await _context.Reviews
							.Where(r => r.PropertyId == propertyId)
							.ToListAsync();
		}

		public async Task<List<Review>> GetTenantReviewsByLandlordAsync(int landlordId, int tenantId)
		{
			return await _context.Reviews
				.Include(r => r.Reviewer)
				.Include(r => r.Reviewee)
				.Include(r => r.Property)
				.Where(r => r.ReviewType == ReviewType.TenantReview &&
							r.ReviewerId == landlordId &&
							r.RevieweeId == tenantId)
				.OrderByDescending(r => r.DateCreated)
				.AsNoTracking()
				.ToListAsync();
		}
	}
}
