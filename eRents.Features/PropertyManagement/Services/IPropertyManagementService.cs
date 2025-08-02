using eRents.Features.PropertyManagement.DTOs;
using eRents.Features.Shared.DTOs;

namespace eRents.Features.PropertyManagement.Services;

/// <summary>
/// Consolidated interface for Property and Maintenance management
/// Combines property lifecycle management with maintenance operations
/// </summary>
public interface IPropertyManagementService
{
    #region Property Operations
    Task<PropertyResponse?> GetPropertyByIdAsync(int propertyId);
    Task<PagedResponse<PropertyResponse>> GetPropertiesAsync(PropertySearchObject search);
    Task<PropertyResponse> CreatePropertyAsync(PropertyRequest request);
    Task<PropertyResponse> UpdatePropertyAsync(int propertyId, PropertyRequest request);
    Task<bool> DeletePropertyAsync(int propertyId);
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

    #region Maintenance Operations
    Task<MaintenanceIssueResponse?> GetMaintenanceIssueByIdAsync(int id);
    Task<List<MaintenanceIssueResponse>> GetUserMaintenanceIssuesAsync(int? propertyId = null, string? status = null, string? priority = null, DateTime? startDate = null, DateTime? endDate = null);
    Task<List<MaintenanceIssueResponse>> GetPropertyMaintenanceIssuesAsync(int propertyId);
    Task<MaintenanceIssueResponse> CreateMaintenanceIssueAsync(MaintenanceIssueRequest request);
    Task<MaintenanceIssueResponse> UpdateMaintenanceIssueAsync(int id, MaintenanceIssueRequest request);
    Task UpdateMaintenanceStatusAsync(int id, MaintenanceStatusUpdateRequest request);
    Task DeleteMaintenanceIssueAsync(int id);
    Task<MaintenanceStatisticsResponse> GetMaintenanceStatisticsAsync();
    Task<PropertyMaintenanceSummaryResponse> GetPropertyMaintenanceSummaryAsync(int propertyId);
    Task<List<MaintenanceIssueResponse>> GetOverdueMaintenanceIssuesAsync();
    Task<List<MaintenanceIssueResponse>> GetUpcomingMaintenanceAsync(int days = 7);
    Task AssignMaintenanceIssueAsync(int issueId, int assignedToUserId);
    Task<List<MaintenanceIssueResponse>> GetAssignedMaintenanceIssuesAsync();
    #endregion
}