using eRents.Domain.Models;
using eRents.Features.Core.Interfaces;
using eRents.Features.PropertyManagement.DTOs;
using eRents.Features.Shared.DTOs;

namespace eRents.Features.PropertyManagement.Services;

/// <summary>
/// Interface for Property CRUD operations
/// Extends the generic ICrudService interface with property-specific operations
/// </summary>
public interface IPropertyService : ICrudService<Property, PropertyRequest, PropertyResponse, PropertySearchObject>
{
    #region Property-Specific Operations
    
    // Custom property operations that don't fit the standard CRUD pattern
    Task UpdateStatusAsync(int propertyId, int statusId);
    Task<PagedResponse<PropertyResponse>> GetPropertiesByRentalTypeAsync(string rentalType, PropertySearchObject? search = null);
    Task<PagedResponse<PropertyResponse>> GetMyPropertiesAsync(PropertySearchObject? search = null);
    Task<PropertyAvailabilityResponse> GetAvailabilityAsync(int propertyId, DateTime? start, DateTime? end);
    Task<bool> CanPropertyAcceptBookingsAsync(int propertyId);
    Task<bool> IsPropertyVisibleInMarketAsync(int propertyId);
    Task<bool> HasActiveAnnualTenantAsync(int propertyId);
    Task<PagedResponse<PropertyResponse>> SearchPropertiesAsync(PropertySearchObject search);
    Task<List<PropertyResponse>> GetPopularPropertiesAsync(int limit = 10);
    Task<bool> SavePropertyAsync(int propertyId, int userId);
    Task<bool> IsPropertyAvailableForRentalTypeAsync(int propertyId, string rentalType, DateOnly? startDate = null, DateOnly? endDate = null);
    Task<string> GetPropertyRentalTypeAsync(int propertyId);
    Task<List<PropertyResponse>> GetAvailablePropertiesForRentalTypeAsync(string rentalType);
    Task<List<PropertyResponse>> GetPropertiesByRentalTypeListAsync(string rentalType);
    
    #endregion
}
