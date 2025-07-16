using eRents.Features.FinancialManagement.DTOs;

namespace eRents.Features.FinancialManagement.Services;

/// <summary>
/// Interface for comprehensive Statistics operations
/// Handles financial metrics, property statistics, maintenance data, and dashboard aggregations
/// </summary>
public interface IStatisticsService
{
    #region Dashboard Statistics

    /// <summary>
    /// Get comprehensive dashboard statistics for current user
    /// Includes property, financial, and maintenance summaries
    /// </summary>
    Task<DashboardStatisticsResponse> GetDashboardStatisticsAsync();

    #endregion

    #region Property Statistics

    /// <summary>
    /// Get property statistics including counts and occupancy rates
    /// </summary>
    Task<PropertyStatisticsResponse> GetPropertyStatisticsAsync();

    #endregion

    #region Maintenance Statistics

    /// <summary>
    /// Get maintenance statistics for current user's properties
    /// </summary>
    Task<MaintenanceStatisticsResponse> GetMaintenanceStatisticsAsync();

    #endregion

    #region Financial Statistics

    /// <summary>
    /// Get detailed financial summary with monthly breakdown
    /// </summary>
    Task<FinancialSummaryResponse> GetFinancialSummaryAsync(FinancialStatisticsRequest request);

    /// <summary>
    /// Get basic financial metrics for current user
    /// </summary>
    Task<FinancialSummaryResponse> GetBasicFinancialStatsAsync();

    /// <summary>
    /// Get monthly revenue data for the current year
    /// </summary>
    Task<List<MonthlyRevenueResponse>> GetCurrentYearRevenueAsync();

    /// <summary>
    /// Get total revenue for specific property
    /// </summary>
    Task<decimal> GetPropertyTotalRevenueAsync(int propertyId);

    /// <summary>
    /// Get maintenance costs for specific property
    /// </summary>
    Task<decimal> GetPropertyMaintenanceCostsAsync(int propertyId, DateTime? startDate = null, DateTime? endDate = null);

    /// <summary>
    /// Get occupancy rate for property
    /// </summary>
    Task<double> GetPropertyOccupancyRateAsync(int propertyId, DateTime? startDate = null, DateTime? endDate = null);

    #endregion
}
