using eRents.Features.MaintenanceManagement.DTOs;

namespace eRents.Features.MaintenanceManagement.Services;

/// <summary>
/// Interface for Maintenance Issue operations
/// Handles reactive maintenance issues, requests, and tracking
/// </summary>
public interface IMaintenanceService
{
    #region Maintenance Issue CRUD

    /// <summary>
    /// Get maintenance issue by ID
    /// </summary>
    Task<MaintenanceIssueResponse?> GetMaintenanceIssueByIdAsync(int id);

    /// <summary>
    /// Get maintenance issues for current user with filtering
    /// </summary>
    Task<List<MaintenanceIssueResponse>> GetUserMaintenanceIssuesAsync(
        int? propertyId = null,
        string? status = null,
        string? priority = null,
        DateTime? startDate = null,
        DateTime? endDate = null);

    /// <summary>
    /// Get maintenance issues for specific property
    /// </summary>
    Task<List<MaintenanceIssueResponse>> GetPropertyMaintenanceIssuesAsync(int propertyId);

    /// <summary>
    /// Create new maintenance issue
    /// </summary>
    Task<MaintenanceIssueResponse> CreateMaintenanceIssueAsync(MaintenanceIssueRequest request);

    /// <summary>
    /// Update existing maintenance issue
    /// </summary>
    Task<MaintenanceIssueResponse> UpdateMaintenanceIssueAsync(int id, MaintenanceIssueRequest request);

    /// <summary>
    /// Update maintenance issue status
    /// </summary>
    Task UpdateMaintenanceStatusAsync(int id, MaintenanceStatusUpdateRequest request);

    /// <summary>
    /// Delete maintenance issue
    /// </summary>
    Task DeleteMaintenanceIssueAsync(int id);

    #endregion

    #region Maintenance Statistics

    /// <summary>
    /// Get maintenance statistics for current user
    /// </summary>
    Task<MaintenanceStatisticsResponse> GetMaintenanceStatisticsAsync();

    /// <summary>
    /// Get maintenance summary for specific property
    /// </summary>
    Task<PropertyMaintenanceSummaryResponse> GetPropertyMaintenanceSummaryAsync(int propertyId);

    /// <summary>
    /// Get overdue maintenance issues (pending issues older than 7 days)
    /// </summary>
    Task<List<MaintenanceIssueResponse>> GetOverdueMaintenanceIssuesAsync();

    /// <summary>
    /// Get recent maintenance issues (last 7 days)
    /// </summary>
    Task<List<MaintenanceIssueResponse>> GetUpcomingMaintenanceAsync(int days = 7);

    #endregion

    #region Maintenance Assignment

    /// <summary>
    /// Assign maintenance issue to user
    /// </summary>
    Task AssignMaintenanceIssueAsync(int issueId, int assignedToUserId);

    /// <summary>
    /// Get maintenance issues assigned to current user
    /// </summary>
    Task<List<MaintenanceIssueResponse>> GetAssignedMaintenanceIssuesAsync();

    #endregion
}
