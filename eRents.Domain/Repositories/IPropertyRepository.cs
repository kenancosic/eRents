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
		// ❌ MOVED TO DEDICATED REPOSITORIES/SERVICES: SoC violations
		// - SearchPropertiesAsync -> use base repository GetPagedAsync/GetAsync  
		// - Amenity methods -> AmenityRepository
		// - Statistics methods -> StatisticsService
		// - Review methods -> ReviewService

		// User-scoped methods for security
		Task<List<Property>> GetByOwnerIdAsync(string ownerId);
		Task<List<Property>> GetAvailablePropertiesAsync();
		Task<bool> IsOwnerAsync(int propertyId, string userId);
		// ❌ REMOVED GetByIdWithOwnerCheckAsync - role filtering is in GetQueryable()
		
		// Get tracked entity for updates
		Task<Property> GetByIdForUpdateAsync(int propertyId);

		// Validation methods for related entities
		Task<bool> IsValidPropertyTypeIdAsync(int propertyTypeId);
		Task<bool> IsValidRentingTypeIdAsync(int rentingTypeId);

		Task<IEnumerable<Property>> GetPopularPropertiesAsync(int count);
		// ❌ REMOVED AddSavedProperty & AddImageAsync - use dedicated services with Unit of Work
		Task<PropertyAvailabilityResponse> GetPropertyAvailability(int propertyId, DateTime? start, DateTime? end);
		Task<IEnumerable<Property>> GetPropertiesByRentalType(string rentalType);
		Task<bool> HasActiveLease(int propertyId);
	}
}
