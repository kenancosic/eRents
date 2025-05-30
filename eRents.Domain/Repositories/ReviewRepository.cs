using eRents.Domain.Models;
using eRents.Domain.Shared;
using Microsoft.EntityFrameworkCore;

namespace eRents.Domain.Repositories
{
	public class ReviewRepository : BaseRepository<Review>, IReviewRepository
	{
		public ReviewRepository(ERentsContext context) : base(context) { }

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
