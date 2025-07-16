using eRents.Features.PropertyManagement.DTOs;
using eRents.Features.Shared.DTOs;
using eRents.Domain.Models.Enums;

namespace eRents.Features.PropertyManagement.Services;

/// <summary>
/// PropertyManagement feature service interface
/// Provides property CRUD operations and business logic
/// </summary>
public interface IPropertyManagementService
{
	#region Core CRUD Operations

	/// <summary>
	/// Get property by ID with includes
	/// </summary>
	Task<PropertyResponse?> GetPropertyByIdAsync(int propertyId);

	/// <summary>
	/// Get properties with filtering and pagination
	/// </summary>
	Task<PagedResponse<PropertyResponse>> GetPropertiesAsync(PropertySearchObject search);

	/// <summary>
	/// Create new property
	/// </summary>
	Task<PropertyResponse> CreatePropertyAsync(PropertyRequest request);

	/// <summary>
	/// Update existing property
	/// </summary>
	Task<PropertyResponse> UpdatePropertyAsync(int propertyId, PropertyRequest request);

	/// <summary>
	/// Delete property
	/// </summary>
	Task<bool> DeletePropertyAsync(int propertyId);

	#endregion

	#region Business Logic Methods

	/// <summary>
	/// Update property status
	/// </summary>
	Task UpdateStatusAsync(int propertyId, PropertyStatusEnum status);

	/// <summary>
	/// Get properties by rental type with pagination
	/// </summary>
	Task<PagedResponse<PropertyResponse>> GetPropertiesByRentalTypeAsync(string rentalType, PropertySearchObject? search = null);

	/// <summary>
	/// Get properties by rental type as list (non-paginated)
	/// </summary>
	Task<List<PropertyResponse>> GetPropertiesByRentalTypeListAsync(string rentalType);

	/// <summary>
	/// Get properties owned by current user with pagination
	/// </summary>
	Task<PagedResponse<PropertyResponse>> GetMyPropertiesAsync(PropertySearchObject? search = null);

	/// <summary>
	/// Get property availability for date range
	/// </summary>
	Task<PropertyAvailabilityResponse> GetAvailabilityAsync(int propertyId, DateTime? start, DateTime? end);

	/// <summary>
	/// Check if property can accept bookings
	/// </summary>
	Task<bool> CanPropertyAcceptBookingsAsync(int propertyId);

	/// <summary>
	/// Check if property is visible in market
	/// </summary>
	Task<bool> IsPropertyVisibleInMarketAsync(int propertyId);

	/// <summary>
	/// Check if property has active annual tenant
	/// </summary>
	Task<bool> HasActiveAnnualTenantAsync(int propertyId);

	/// <summary>
	/// Save property to user's saved properties list
	/// </summary>
	Task<bool> SavePropertyAsync(int propertyId, int userId);

	/// <summary>
	/// Check if property is available for specific rental type
	/// </summary>
	Task<bool> IsPropertyAvailableForRentalTypeAsync(int propertyId, string rentalType, DateOnly? startDate = null, DateOnly? endDate = null);

	/// <summary>
	/// Get property's rental type
	/// </summary>
	Task<string> GetPropertyRentalTypeAsync(int propertyId);

	/// <summary>
	/// Get available properties for specific rental type
	/// </summary>
	Task<List<PropertyResponse>> GetAvailablePropertiesForRentalTypeAsync(string rentalType);

	#endregion

	#region Extended Property Operations

	/// <summary>
	/// Search properties with advanced filtering
	/// </summary>
	Task<PagedResponse<PropertyResponse>> SearchPropertiesAsync(PropertySearchObject search);

	/// <summary>
	/// Get popular properties based on bookings and ratings
	/// </summary>
	Task<List<PropertyResponse>> GetPopularPropertiesAsync(int limit = 10);

	#endregion
}