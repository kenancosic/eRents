using eRents.Domain.Models;
using eRents.Domain.Shared;
using eRents.Shared.SearchObjects;

namespace eRents.Domain.Repositories
{
	public interface IPropertyRepository : IBaseRepository<Property>
	{
		Task<IEnumerable<Property>> SearchPropertiesAsync(PropertySearchObject searchObject);
		Task<IEnumerable<Amenity>> GetAmenitiesByIdsAsync(IEnumerable<int> amenityIds);
		Task<IEnumerable<Amenity>> GetAllAmenitiesAsync();
		Task<decimal> GetTotalRevenueAsync(int propertyId);
		Task<int> GetNumberOfBookingsAsync(int propertyId);
		Task<int> GetNumberOfTenantsAsync(int propertyId);
		Task<decimal> GetAverageRatingAsync(int propertyId);
		Task<int> GetNumberOfReviewsAsync(int propertyId);
		public Task<IEnumerable<Review>> GetAllRatings();

		// User-scoped methods for security
		Task<List<Property>> GetByOwnerIdAsync(string ownerId);
		Task<List<Property>> GetAvailablePropertiesAsync();
		Task<bool> IsOwnerAsync(int propertyId, string userId);
		Task<Property> GetByIdWithOwnerCheckAsync(int propertyId, string currentUserId, string currentUserRole);
	}
}
