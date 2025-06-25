using eRents.Shared.DTO.Response;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace eRents.Application.Services.ReportService
{
    /// <summary>
    /// ✅ ENHANCED: Report service interface focused on presentation and formatting
    /// Delegates financial calculations to StatisticsService to eliminate redundancy
    /// Specializes in transforming aggregate data into detailed property-level reports
    /// </summary>
    public interface IReportService
    {
        /// <summary>
        /// ✅ DELEGATED: Uses StatisticsService for calculations, focuses on property-level presentation
        /// Generates detailed financial reports by property for specified date range
        /// </summary>
        Task<List<FinancialReportResponse>> GetFinancialReportAsync(int userId, DateTime startDate, DateTime endDate);
        
        /// <summary>
        /// ✅ SPECIALIZED: Tenant-focused reporting with booking details
        /// Provides tenant activity and lease information for landlord properties
        /// </summary>
        Task<List<TenantReportResponse>> GetTenantReportAsync(int userId, DateTime startDate, DateTime endDate);
    }
} 