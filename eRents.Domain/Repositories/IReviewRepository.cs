using eRents.Domain.Models;
using eRents.Domain.Shared;

namespace eRents.Domain.Repositories
{
	public interface IReviewRepository : IBaseRepository<Review>
	{
		Task<decimal> GetAverageRatingAsync(int propertyId);
		Task<IEnumerable<Review>> GetReviewsByPropertyAsync(int propertyId);
		
		// Tenant review methods
		Task<List<Review>> GetTenantReviewsByLandlordAsync(int landlordId, int tenantId);
	}
}