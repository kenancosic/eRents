using eRents.Application.Shared;
using eRents.Shared.DTO.Requests; // For InsertRequest, UpdateRequest, SearchObject
using eRents.Shared.DTO.Response; // For Response
using eRents.Shared.Enums;
using eRents.Shared.SearchObjects;
using System.Collections.Generic; // Added for List
using System.Threading.Tasks; // Added for Task

namespace eRents.Application.Services.PropertyService
{
	public interface IPropertyService : ICRUDService<PropertyResponse, PropertySearchObject, PropertyInsertRequest, PropertyUpdateRequest>
	{
		Task<PagedList<PropertySummaryResponse>> SearchPropertiesAsync(PropertySearchObject searchRequest);
		Task<List<PropertySummaryResponse>> GetPopularPropertiesAsync();

		// Additional custom methods
		Task<bool> SavePropertyAsync(int propertyId, int userId);
		// ❌ MOVED TO RECOMMENDATION SERVICE: ML logic violates SoC

		// Methods from a potential ICRUDService (example)
		// Task<PropertyResponse> GetByIdAsync(string id);
		// Task<IEnumerable<PropertyResponse>> GetAsync(PropertySearchObject search = null);
		// Task<PropertyResponse> InsertAsync(PropertyInsertRequest insert);
		// Task<PropertyResponse> UpdateAsync(string id, PropertyUpdateRequest update);
		// Task<PropertyResponse> DeleteAsync(string id);
		// ❌ REMOVED UploadImageAsync - image operations are handled by ImageService
		Task UpdateStatusAsync(int propertyId, PropertyStatusEnum statusEnum);
		Task<PropertyAvailabilityResponse> GetAvailabilityAsync(int propertyId, DateTime? start, DateTime? end);

		// 🆕 NEW: Dual Rental System Support
		Task<bool> IsPropertyAvailableForRentalTypeAsync(int propertyId, string rentalType, DateOnly? startDate = null, DateOnly? endDate = null);
		Task<bool> IsPropertyVisibleInMarketAsync(int propertyId);
		Task<List<PropertyResponse>> GetPropertiesByRentalTypeAsync(string rentalType);
		Task<bool> CanPropertyAcceptBookingsAsync(int propertyId);
		Task<bool> HasActiveAnnualTenantAsync(int propertyId);

		// ✅ Phase 3: Property Management Methods (moved from SimpleRentalService)
		// ❌ REMOVED UpdatePropertyAvailabilityAsync - use UpdateStatusAsync instead
		Task<string> GetPropertyRentalTypeAsync(int propertyId);
		Task<List<PropertyResponse>> GetAvailablePropertiesForRentalTypeAsync(string rentalType);
	}
}
