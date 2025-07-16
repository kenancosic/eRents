using eRents.Features.FinancialManagement.DTOs;

namespace eRents.Features.FinancialManagement.Services;

/// <summary>
/// Interface for Financial Reporting operations
/// Handles property-level and tenant-level financial reports
/// </summary>
public interface IReportService
{
    #region Financial Reports

    /// <summary>
    /// Get financial report for properties within date range
    /// </summary>
    Task<List<FinancialReportResponse>> GetFinancialReportAsync(DateTime startDate, DateTime endDate, int? propertyId = null);

    /// <summary>
    /// Get financial summary for current user's properties
    /// </summary>
    Task<FinancialSummaryResponse> GetFinancialSummaryAsync(DateTime startDate, DateTime endDate, int? propertyId = null);

    /// <summary>
    /// Get monthly revenue breakdown for the year
    /// </summary>
    Task<List<MonthlyRevenueResponse>> GetMonthlyRevenueAsync(int year, int? propertyId = null);

    #endregion

    #region Tenant Reports

    /// <summary>
    /// Get tenant activity report for current user's properties within date range
    /// </summary>
    Task<List<TenantReportResponse>> GetTenantReportAsync(DateTime startDate, DateTime endDate, int? propertyId = null);

    #endregion
} 
