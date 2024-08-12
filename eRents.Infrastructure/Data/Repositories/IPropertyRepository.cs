using eRents.Domain.Entities;
using eRents.Infrastructure.Data.Shared;
using eRents.Shared.SearchObjects;

namespace eRents.Infrastructure.Data.Repositories
{
	public interface IPropertyRepository : IBaseRepository<Property>
	{
		Task<IEnumerable<Property>> SearchPropertiesAsync(PropertySearchObject searchObject);
		Task<IEnumerable<Amenity>> GetAmenitiesByIdsAsync(IEnumerable<int> amenityIds);
		Task<Property> GetPropertyByIdAsync(int propertyId);
		Task<decimal> GetTotalRevenueAsync(int propertyId);
		Task<int> GetNumberOfBookingsAsync(int propertyId);
		Task<int> GetNumberOfTenantsAsync(int propertyId);
		Task<decimal> GetAverageRatingAsync(int propertyId);
		Task<int> GetNumberOfReviewsAsync(int propertyId);
	}
}
