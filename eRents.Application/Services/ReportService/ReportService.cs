using eRents.Application.Services.StatisticsService;
using eRents.Domain.Repositories;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Threading.Tasks;

namespace eRents.Application.Services.ReportService
{
    /// <summary>
    /// ✅ ENHANCED: Report service focused on presentation and formatting
    /// Delegates financial calculations to StatisticsService to eliminate redundancy
    /// Transforms aggregate statistics into detailed property-level reports
    /// </summary>
    public class ReportService : IReportService
    {
        #region Dependencies
        private readonly IStatisticsService _statisticsService;
        private readonly IPropertyRepository _propertyRepository;
        private readonly IBookingRepository _bookingRepository;
        private readonly IUserRepository _userRepository;

        public ReportService(
            IStatisticsService statisticsService,
            IPropertyRepository propertyRepository,
            IBookingRepository bookingRepository,
            IUserRepository userRepository)
        {
            _statisticsService = statisticsService;
            _propertyRepository = propertyRepository;
            _bookingRepository = bookingRepository;
            _userRepository = userRepository;
        }
        #endregion

        #region Financial Reports

        public async Task<List<FinancialReportResponse>> GetFinancialReportAsync(int userId, DateTime startDate, DateTime endDate)
        {
            // ✅ DELEGATION: Use StatisticsService for financial calculations instead of duplicating logic
            var financialSummaryRequest = new FinancialStatisticsRequest
            {
                StartDate = startDate,
                EndDate = endDate
            };

            var financialSummary = await _statisticsService.GetFinancialSummaryAsync(userId, financialSummaryRequest);

            // ✅ REPORT FOCUS: Transform aggregate statistics into property-level detailed reports
            return await GeneratePropertyLevelReportsAsync(userId, startDate, endDate, financialSummary);
        }

        /// <summary>
        /// ✅ ENHANCED: Generate detailed property-level reports using aggregate data as reference
        /// Focuses on report formatting and presentation rather than financial calculations
        /// </summary>
        private async Task<List<FinancialReportResponse>> GeneratePropertyLevelReportsAsync(
            int userId, 
            DateTime startDate, 
            DateTime endDate, 
            FinancialSummaryResponse financialSummary)
        {
            var startDateOnly = DateOnly.FromDateTime(startDate);
            var endDateOnly = DateOnly.FromDateTime(endDate);

            // ✅ SIMPLIFIED: Get properties with minimal navigation for report generation
            var landlordProperties = await _propertyRepository.GetQueryable()
                .Where(p => p.OwnerId == userId)
                .Include(p => p.Bookings.Where(b => b.StartDate >= startDateOnly && b.StartDate <= endDateOnly))
                .Include(p => p.MaintenanceIssues.Where(m => m.CreatedAt >= startDate && m.CreatedAt <= endDate && m.Cost.HasValue))
                .ToListAsync();

            var financialReports = new List<FinancialReportResponse>();

            foreach (var property in landlordProperties)
            {
                // ✅ REPORT LOGIC: Simple aggregation for property-level view
                var periodBookings = property.Bookings ?? new List<Domain.Models.Booking>();
                var totalRent = periodBookings.Sum(b => b.TotalPrice);

                var periodMaintenance = property.MaintenanceIssues ?? new List<Domain.Models.MaintenanceIssue>();
                var maintenanceCosts = periodMaintenance.Sum(m => m.Cost ?? 0);

                // ✅ PRESENTATION: Only include properties with activity for clean reporting
                if (totalRent > 0 || maintenanceCosts > 0)
                {
                    financialReports.Add(new FinancialReportResponse
                    {
                        DateFrom = FormatDateForReport(startDate),
                        DateTo = FormatDateForReport(endDate),
                        Property = property.Name,
                        TotalRent = totalRent,
                        MaintenanceCosts = maintenanceCosts,
                        Total = totalRent - maintenanceCosts
                    });
                }
            }

            return financialReports.OrderBy(r => r.Property).ToList();
        }

        #endregion

        #region Tenant Reports

        public async Task<List<TenantReportResponse>> GetTenantReportAsync(int userId, DateTime startDate, DateTime endDate)
        {
            var startDateOnly = DateOnly.FromDateTime(startDate);
            var endDateOnly = DateOnly.FromDateTime(endDate);

            // ✅ TENANT REPORTS: Focused query for tenant reporting (different from financial aggregation)
            var tenantReports = await _bookingRepository.GetQueryable()
                .Include(b => b.Property)
                .Include(b => b.User)
                .Where(b => b.Property!.OwnerId == userId &&
                           b.StartDate >= startDateOnly && b.StartDate <= endDateOnly)
                .Select(b => new TenantReportResponse
                {
                    LeaseStart = FormatDateForReport(b.StartDate),
                    LeaseEnd = b.EndDate.HasValue ? FormatDateForReport(b.EndDate.Value) : "Ongoing",
                    Tenant = b.User!.FirstName + " " + b.User.LastName,
                    Property = b.Property!.Name,
                    CostOfRent = b.TotalPrice,
                    TotalPaidRent = b.TotalPrice // ✅ BUSINESS RULE: Assuming full payment for simplicity
                })
                .ToListAsync();

            return tenantReports.OrderBy(r => r.Tenant).ThenBy(r => r.Property).ToList();
        }

        #endregion

        #region Helper Methods

        /// <summary>
        /// ✅ CONSOLIDATED: Single date formatting method for consistent report presentation
        /// Replaces duplicate date formatting patterns throughout the service
        /// </summary>
        private static string FormatDateForReport(DateTime date)
        {
            return date.ToString("dd/MM/yyyy");
        }

        /// <summary>
        /// ✅ PRESENTATION: Overload for DateOnly formatting
        /// </summary>
        private static string FormatDateForReport(DateOnly date)
        {
            return date.ToString("dd/MM/yyyy");
        }

        #endregion
    }
} 