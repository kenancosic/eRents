using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using System.Threading.Tasks;
using System.Collections.Generic; // For List in PropertyStatisticsResponse placeholder
using eRents.Domain.Repositories;
using Microsoft.EntityFrameworkCore;
using System.Linq;
using System;

namespace eRents.Application.Services.StatisticsService
{
    /// <summary>
    /// ✅ ENHANCED: Clean statistics service with proper SoC
    /// Focuses on high-level statistics aggregation for dashboard and analytics
    /// Delegates detailed financial analysis to specialized calculation methods
    /// </summary>
    public class StatisticsService : IStatisticsService
    {
        #region Dependencies
        private readonly IPropertyRepository _propertyRepository;
        private readonly IBookingRepository _bookingRepository;
        private readonly IMaintenanceRepository _maintenanceRepository;

        public StatisticsService(
            IPropertyRepository propertyRepository,
            IBookingRepository bookingRepository,
            IMaintenanceRepository maintenanceRepository)
        {
            _propertyRepository = propertyRepository;
            _bookingRepository = bookingRepository;
            _maintenanceRepository = maintenanceRepository;
        }
        #endregion

        #region Dashboard Statistics

        public async Task<DashboardStatisticsResponse> GetDashboardStatisticsAsync(int userId)
        {
            // ✅ PARALLEL: Execute independent statistics queries in parallel for better performance
            var (propertyStats, maintenanceStats, financialStats, averageRating) = await ExecuteParallelStatisticsQueries(userId);
            var topProperties = await GetTopPropertiesAsync(userId);

            return new DashboardStatisticsResponse
            {
                TotalProperties = propertyStats.TotalProperties,
                OccupiedProperties = propertyStats.RentedUnits,
                OccupancyRate = propertyStats.OccupancyRate,
                AverageRating = averageRating,
                TopPropertyIds = topProperties.Select(p => p.PropertyId).ToList(),
                PendingMaintenanceIssues = maintenanceStats.PendingIssuesCount,
                MonthlyRevenue = financialStats.MonthlyRevenue,
                YearlyRevenue = financialStats.YearlyRevenue,
                TotalRentIncome = (double)financialStats.TotalRentIncome,
                TotalMaintenanceCosts = (double)financialStats.TotalMaintenanceCosts,
                NetTotal = (double)financialStats.NetTotal
            };
        }

        /// <summary>
        /// ✅ PERFORMANCE: Execute independent statistics queries in parallel
        /// Reduces total execution time by running non-dependent queries simultaneously
        /// </summary>
        private async Task<(PropertyStatisticsResponse PropertyStats, MaintenanceStatisticsResponse MaintenanceStats, DashboardFinancialStats FinancialStats, double AverageRating)> ExecuteParallelStatisticsQueries(int userId)
        {
            var propertyStatsTask = GetPropertyStatisticsAsync(userId);
            var maintenanceStatsTask = GetMaintenanceStatisticsAsync(userId);
            var financialStatsTask = GetDashboardFinancialStatsAsync(userId);
            var averageRatingTask = GetAveragePropertyRatingAsync(userId);

            await Task.WhenAll(propertyStatsTask, maintenanceStatsTask, financialStatsTask, averageRatingTask);

            return (
                await propertyStatsTask,
                await maintenanceStatsTask,
                await financialStatsTask,
                await averageRatingTask
            );
        }

        #endregion

        #region Individual Statistics Methods

        public async Task<PropertyStatisticsResponse> GetPropertyStatisticsAsync(int userId)
        {
            // ✅ OPTIMIZED: Single query to get property counts by status
            var propertyStatusCounts = await _propertyRepository.GetQueryable()
                .Where(p => p.OwnerId == userId)
                .GroupBy(p => p.Status)
                .Select(g => new { Status = g.Key, Count = g.Count() })
                .ToListAsync();

            var total = propertyStatusCounts.Sum(g => g.Count);
            var available = propertyStatusCounts.FirstOrDefault(g => g.Status == "AVAILABLE")?.Count ?? 0;
            var rented = propertyStatusCounts.FirstOrDefault(g => g.Status == "RENTED")?.Count ?? 0;
            double occupancyRate = total > 0 ? (double)rented / total : 0.0;

            // ✅ SEPARATE QUERY: Get vacant properties preview only when needed
            var vacantPreview = await GetVacantPropertiesPreviewAsync(userId);

            return new PropertyStatisticsResponse
            {
                TotalProperties = total,
                AvailableUnits = available,
                RentedUnits = rented,
                OccupancyRate = occupancyRate,
                VacantPropertiesPreview = vacantPreview
            };
        }

        public async Task<MaintenanceStatisticsResponse> GetMaintenanceStatisticsAsync(int userId)
        {
            // ✅ OPTIMIZED: Get property IDs once, then use consolidated repository methods
            var propertyIds = await GetUserPropertyIds(userId);

            // ✅ PARALLEL: Execute maintenance counting queries in parallel
            var openTask = _maintenanceRepository.CountByStatusAsync(propertyIds, "pending");
            var highPriorityTask = _maintenanceRepository.CountByPriorityAsync(propertyIds, "High", "Emergency");
            var tenantComplaintsTask = _maintenanceRepository.CountTenantComplaintsAsync(propertyIds);

            await Task.WhenAll(openTask, highPriorityTask, tenantComplaintsTask);

            var open = await openTask;
            var highPriority = await highPriorityTask;
            var tenantComplaints = await tenantComplaintsTask;

            return new MaintenanceStatisticsResponse
            {
                OpenIssuesCount = open,
                PendingIssuesCount = open, // Same as open for consistency
                HighPriorityIssuesCount = highPriority,
                TenantComplaintsCount = tenantComplaints
            };
        }

        public async Task<FinancialSummaryResponse> GetFinancialSummaryAsync(int userId, FinancialStatisticsRequest request)
        {
            // ✅ ENHANCED: Delegate to specialized financial calculation service
            return await CalculateDetailedFinancialSummaryAsync(userId, request);
        }

        #endregion

        #region Supporting Methods

        /// <summary>
        /// ✅ CONSOLIDATED: Get top properties with consistent calculation logic
        /// Eliminates duplicate revenue and rating calculations
        /// </summary>
        private async Task<List<PopularPropertyResponse>> GetTopPropertiesAsync(int userId)
        {
            var properties = await _propertyRepository.GetQueryable()
                .Where(p => p.OwnerId == userId)
                .Include(p => p.Bookings)
                .Include(p => p.Reviews.Where(r => r.StarRating.HasValue))
                .OrderByDescending(p => p.Bookings.Count())
                .Take(5)
                .ToListAsync();

            return properties.Select(p => new PopularPropertyResponse
            {
                PropertyId = p.PropertyId,
                Name = p.Name,
                BookingCount = p.Bookings?.Count() ?? 0,
                TotalRevenue = CalculatePropertyRevenue(p),
                AverageRating = CalculatePropertyAverageRating(p)
            }).ToList();
        }

        /// <summary>
        /// ✅ DASHBOARD FOCUSED: Simplified financial stats for dashboard (not detailed analysis)
        /// Returns only what's needed for dashboard display
        /// </summary>
        private async Task<DashboardFinancialStats> GetDashboardFinancialStatsAsync(int userId)
        {
            var currentDate = DateTime.Now;
            var currentMonth = new DateTime(currentDate.Year, currentDate.Month, 1);
            var currentYear = new DateTime(currentDate.Year, 1, 1);

            // ✅ PARALLEL: Get monthly and yearly revenue simultaneously
            var monthlyRevenueTask = GetRevenueForPeriodAsync(userId, currentMonth, currentDate);
            var yearlyRevenueTask = GetRevenueForPeriodAsync(userId, currentYear, currentDate);
            var totalStatsTask = GetLifetimeFinancialStatsAsync(userId);

            await Task.WhenAll(monthlyRevenueTask, yearlyRevenueTask, totalStatsTask);

            var (totalRent, totalMaintenance) = await totalStatsTask;

            return new DashboardFinancialStats
            {
                MonthlyRevenue = await monthlyRevenueTask,
                YearlyRevenue = await yearlyRevenueTask,
                TotalRentIncome = totalRent,
                TotalMaintenanceCosts = totalMaintenance,
                NetTotal = totalRent - totalMaintenance
            };
        }

        /// <summary>
        /// ✅ CONSOLIDATED: Single method for period-based revenue calculation
        /// Eliminates duplication between monthly and yearly revenue methods
        /// </summary>
        private async Task<double> GetRevenueForPeriodAsync(int userId, DateTime startDate, DateTime endDate)
        {
            var startDateOnly = DateOnly.FromDateTime(startDate);
            var endDateOnly = DateOnly.FromDateTime(endDate);

            var revenue = await _bookingRepository.GetQueryable()
                .Include(b => b.Property)
                .Where(b => b.Property.OwnerId == userId &&
                           b.StartDate >= startDateOnly && b.StartDate <= endDateOnly)
                .SumAsync(b => (double)b.TotalPrice);

            return revenue;
        }

        /// <summary>
        /// ✅ CONSOLIDATED: Single average rating calculation method
        /// Replaces duplicate rating logic across GetAveragePropertyRatingAsync and GetTopPropertiesAsync
        /// </summary>
        private async Task<double> GetAveragePropertyRatingAsync(int userId)
        {
            var averageRating = await _propertyRepository.GetQueryable()
                .Where(p => p.OwnerId == userId)
                .SelectMany(p => p.Reviews.Where(r => r.StarRating.HasValue))
                .AverageAsync(r => (double?)r.StarRating) ?? 0.0;

            return averageRating;
        }

        #endregion

        #region Helper Methods

        /// <summary>
        /// ✅ REUSABLE: Get user property IDs for maintenance and other cross-entity queries
        /// </summary>
        private async Task<List<int>> GetUserPropertyIds(int userId)
        {
            return await _propertyRepository.GetQueryable()
                .Where(p => p.OwnerId == userId)
                .Select(p => p.PropertyId)
                .ToListAsync();
        }

        /// <summary>
        /// ✅ FOCUSED: Get vacant properties preview for property statistics
        /// </summary>
        private async Task<List<PropertyMiniSummaryResponse>> GetVacantPropertiesPreviewAsync(int userId)
        {
            return await _propertyRepository.GetQueryable()
                .Where(p => p.OwnerId == userId && p.Status == "AVAILABLE")
                .Take(5)
                .Select(p => new PropertyMiniSummaryResponse
                {
                    PropertyId = p.PropertyId.ToString(),
                    Title = p.Name,
                    Price = p.Price
                })
                .ToListAsync();
        }

        /// <summary>
        /// ✅ LIFETIME STATS: Get total revenue and maintenance for all time
        /// </summary>
        private async Task<(decimal TotalRent, decimal TotalMaintenance)> GetLifetimeFinancialStatsAsync(int userId)
        {
            var propertyIds = await GetUserPropertyIds(userId);

            var totalRentTask = _bookingRepository.GetQueryable()
                .Include(b => b.Property)
                .Where(b => b.Property.OwnerId == userId)
                .SumAsync(b => b.TotalPrice);

            var totalMaintenanceTask = _maintenanceRepository.GetQueryable()
                .Where(m => propertyIds.Contains(m.PropertyId) && m.Cost.HasValue)
                .SumAsync(m => m.Cost ?? 0);

            await Task.WhenAll(totalRentTask, totalMaintenanceTask);

            return (await totalRentTask, await totalMaintenanceTask);
        }

        /// <summary>
        /// ✅ CONSOLIDATED: Single property revenue calculation method
        /// Used by multiple methods to ensure consistency
        /// </summary>
        private static double CalculatePropertyRevenue(Domain.Models.Property property)
        {
            return property.Bookings?.Sum(b => (double)b.TotalPrice) ?? 0.0;
        }

        /// <summary>
        /// ✅ CONSOLIDATED: Single property rating calculation method
        /// Used by multiple methods to ensure consistency
        /// </summary>
        private static double? CalculatePropertyAverageRating(Domain.Models.Property property)
        {
            var ratingsWithValues = property.Reviews?.Where(r => r.StarRating.HasValue).ToList();
            return ratingsWithValues?.Any() == true
                ? (double)ratingsWithValues.Average(r => r.StarRating!.Value)
                : null;
        }

        /// <summary>
        /// ✅ DETAILED ANALYSIS: Complex financial summary calculation for detailed reporting
        /// Separated from dashboard statistics for better SoC
        /// </summary>
        private async Task<FinancialSummaryResponse> CalculateDetailedFinancialSummaryAsync(int userId, FinancialStatisticsRequest request)
        {
            // Get properties with necessary includes for financial analysis
            var landlordProperties = await _propertyRepository.GetQueryable()
                .Where(p => p.OwnerId == userId)
                .Include(p => p.MaintenanceIssues)
                .Include(p => p.Bookings)
                .ToListAsync();

            var startDate = request.StartDate ?? DateTime.MinValue;
            var endDate = request.EndDate ?? DateTime.MaxValue;
            var startDateOnly = DateOnly.FromDateTime(startDate);
            var endDateOnly = DateOnly.FromDateTime(endDate);

            decimal totalRent = 0;
            decimal totalMaintenance = 0;
            var monthlyData = new Dictionary<(int Year, int Month), (decimal Revenue, decimal Maintenance)>();

            // ✅ FINANCIAL ANALYSIS: Process properties for detailed financial breakdown
            foreach (var property in landlordProperties)
            {
                ProcessPropertyFinancials(property, startDate, endDate, startDateOnly, endDateOnly, 
                    ref totalRent, ref totalMaintenance, monthlyData);
            }

            var revenueHistory = monthlyData
                .Select(kvp => new MonthlyRevenueResponse
                {
                    Year = kvp.Key.Year,
                    Month = kvp.Key.Month,
                    Revenue = kvp.Value.Revenue,
                    MaintenanceCosts = kvp.Value.Maintenance
                })
                .OrderBy(m => m.Year)
                .ThenBy(m => m.Month)
                .ToList();

            return new FinancialSummaryResponse
            {
                TotalRentIncome = totalRent,
                TotalMaintenanceCosts = totalMaintenance,
                OtherIncome = 0,
                OtherExpenses = 0,
                NetTotal = totalRent - totalMaintenance,
                RevenueHistory = revenueHistory
            };
        }

        /// <summary>
        /// ✅ EXTRACTED: Process individual property financials for detailed analysis
        /// Keeps the main method focused while handling complex per-property logic
        /// </summary>
        private static void ProcessPropertyFinancials(
            Domain.Models.Property property,
            DateTime startDate,
            DateTime endDate,
            DateOnly startDateOnly,
            DateOnly endDateOnly,
            ref decimal totalRent,
            ref decimal totalMaintenance,
            Dictionary<(int Year, int Month), (decimal Revenue, decimal Maintenance)> monthlyData)
        {
            // Process bookings within date range
            if (property.Bookings != null)
            {
                var filteredBookings = property.Bookings.Where(b => b.StartDate >= startDateOnly && b.StartDate <= endDateOnly);
                
                foreach (var booking in filteredBookings)
                {
                    totalRent += booking.TotalPrice;
                    
                    var bookingDate = booking.StartDate.ToDateTime(TimeOnly.MinValue);
                    var key = (bookingDate.Year, bookingDate.Month);
                    if (!monthlyData.ContainsKey(key))
                        monthlyData[key] = (0m, 0m);
                    var currentData = monthlyData[key];
                    monthlyData[key] = (currentData.Revenue + booking.TotalPrice, currentData.Maintenance);
                }
            }
            
            // Process maintenance within date range
            if (property.MaintenanceIssues != null)
            {
                var filteredMaintenance = property.MaintenanceIssues
                    .Where(m => m.Cost.HasValue && m.CreatedAt >= startDate && m.CreatedAt <= endDate);
                
                foreach (var maintenance in filteredMaintenance)
                {
                    totalMaintenance += maintenance.Cost.Value;
                    
                    var key = (maintenance.CreatedAt.Year, maintenance.CreatedAt.Month);
                    if (!monthlyData.ContainsKey(key))
                        monthlyData[key] = (0m, 0m);
                    var currentData = monthlyData[key];
                    monthlyData[key] = (currentData.Revenue, currentData.Maintenance + maintenance.Cost.Value);
                }
            }
        }

        #endregion
    }

    /// <summary>
    /// ✅ HELPER: Internal class for dashboard financial statistics
    /// Separates dashboard stats from detailed financial analysis
    /// </summary>
    internal class DashboardFinancialStats
    {
        public double MonthlyRevenue { get; set; }
        public double YearlyRevenue { get; set; }
        public decimal TotalRentIncome { get; set; }
        public decimal TotalMaintenanceCosts { get; set; }
        public decimal NetTotal { get; set; }
    }
} 