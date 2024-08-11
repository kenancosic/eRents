using eRents.Domain.Entities;
using eRents.Infrastructure.Data.Shared;
using eRents.Shared.SearchObjects;

namespace eRents.Infrastructure.Data.Repositories
{
	public interface IPropertyRepository : IBaseRepository<Property>
	{
		IEnumerable<Amenity> GetAmenitiesByIds(IEnumerable<int> amenityIds);
		Task<IEnumerable<Property>> SearchPropertiesAsync(PropertySearchObject searchObject);

		Task<decimal> GetTotalRevenue(int propertyId);
		Task<int> GetNumberOfBookings(int propertyId);
		Task<int> GetNumberOfTenants(int propertyId);
		Task<decimal> GetAverageRating(int propertyId);
		Task<int> GetNumberOfReviews(int propertyId);
	}
}