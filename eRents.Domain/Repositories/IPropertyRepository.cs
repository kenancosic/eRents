using eRents.Domain.Models;
using eRents.Domain.Shared;
using eRents.Shared.DTO.Response;
using eRents.Shared.SearchObjects;
using System.Collections.Generic;
using System.Threading.Tasks;
using System;

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
		
		/// <summary>
		/// Get paginated ratings for UI display purposes
		/// </summary>
		Task<PagedList<Review>> GetRatingsPagedAsync(int? propertyId = null, int page = 1, int pageSize = 10);

		// User-scoped methods for security
		Task<List<Property>> GetByOwnerIdAsync(string ownerId);
		Task<List<Property>> GetAvailablePropertiesAsync();
		Task<bool> IsOwnerAsync(int propertyId, string userId);
		Task<Property> GetByIdWithOwnerCheckAsync(int propertyId, string currentUserId, string currentUserRole);
		
		// Get tracked entity for updates
		Task<Property> GetByIdForUpdateAsync(int propertyId);

		// Validation methods for related entities
		Task<bool> IsValidPropertyTypeIdAsync(int propertyTypeId);
		Task<bool> IsValidRentingTypeIdAsync(int rentingTypeId);

		Task<IEnumerable<Property>> GetPopularPropertiesAsync(int count);
		Task<bool> AddSavedProperty(int propertyId, int userId);
		Task AddImageAsync(Image image);
		Task<PropertyAvailabilityResponse> GetPropertyAvailability(int propertyId, DateTime? start, DateTime? end);
		Task<IEnumerable<Property>> GetPropertiesByRentalType(string rentalType);
		Task<bool> HasActiveLease(int propertyId);
		Task UpdatePropertyAmenities(int propertyId, List<int> amenityIds);
		Task UpdatePropertyImages(int propertyId, List<int> imageIds);
	}
}
