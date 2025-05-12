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

	}
}
