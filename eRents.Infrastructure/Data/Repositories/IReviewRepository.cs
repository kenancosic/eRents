using eRents.Domain.Entities;
using eRents.Infrastructure.Data.Shared;

namespace eRents.Infrastructure.Data.Repositories
{
	public interface IReviewRepository : IBaseRepository<Review>
	{
		Task<decimal> GetAverageRatingAsync(int propertyId);
		Task<IEnumerable<Review>> GetReviewsByPropertyAsync(int propertyId);
	}
}