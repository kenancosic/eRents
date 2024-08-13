using eRents.Domain.Entities;
using eRents.Infrastructure.Data.Context;
using eRents.Infrastructure.Data.Shared;
using Microsoft.EntityFrameworkCore;

namespace eRents.Infrastructure.Data.Repositories
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
		public async Task<IEnumerable<Review>> GetComplaintsForPropertyAsync(int propertyId)
		{
			return await _context.Reviews
					.Where(r => r.PropertyId == propertyId && r.IsComplaint == true)
					.ToListAsync();
		}
	}
}
