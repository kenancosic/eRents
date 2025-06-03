using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using System.Threading.Tasks;
using System.Collections.Generic; // For List in PropertyStatisticsResponse placeholder
using eRents.Domain.Repositories;
using Microsoft.EntityFrameworkCore;
using System.Linq;
using System;

namespace eRents.Application.Service.StatisticsService
{
    public class StatisticsService : IStatisticsService
    {
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

        public async Task<DashboardStatisticsResponse> GetDashboardStatisticsAsync(int userId)
        {
            var propertyStats = await GetPropertyStatisticsAsync(userId);
            var maintenanceStats = await GetMaintenanceStatisticsAsync(userId);
            var financialStats = await GetFinancialSummaryAsync(userId, new FinancialStatisticsRequest());
            var topProperties = await GetTopPropertiesAsync(userId);
            var monthlyRevenue = await GetMonthlyRevenueAsync(userId);
            var yearlyRevenue = await GetYearlyRevenueAsync(userId);
            var averageRating = await GetAveragePropertyRatingAsync(userId);

            return new DashboardStatisticsResponse
            {
                TotalProperties = propertyStats.TotalProperties,
                OccupiedProperties = propertyStats.RentedUnits,
                OccupancyRate = propertyStats.OccupancyRate,
                AverageRating = averageRating,
                TopProperties = topProperties,
                PendingMaintenanceIssues = maintenanceStats.PendingIssuesCount,
                MonthlyRevenue = monthlyRevenue,
                YearlyRevenue = yearlyRevenue,
                TotalRentIncome = (double)financialStats.TotalRentIncome,
                TotalMaintenanceCosts = (double)financialStats.TotalMaintenanceCosts,
                NetTotal = (double)financialStats.NetTotal
            };
        }

        private async Task<List<PopularPropertyResponse>> GetTopPropertiesAsync(int userId)
        {
            var properties = await _propertyRepository.GetQueryable()
                .Where(p => p.OwnerId == userId)
                .Include(p => p.Bookings)
                .Include(p => p.Reviews)
                .OrderByDescending(p => p.Bookings.Count())
                .Take(5)
                .ToListAsync();

            return properties.Select(p => new PopularPropertyResponse
            {
                PropertyId = p.PropertyId,
                Name = p.Name,
                BookingCount = p.Bookings?.Count() ?? 0,
                TotalRevenue = CalculatePropertyRevenue(p),
                AverageRating = p.Reviews?.Any() == true && p.Reviews.Any(r => r.StarRating.HasValue) 
                    ? (double)p.Reviews.Where(r => r.StarRating.HasValue).Average(r => r.StarRating!.Value) 
                    : null
            }).ToList();
        }

        private async Task<double> GetMonthlyRevenueAsync(int userId)
        {
            var currentMonth = DateTime.Now.Month;
            var currentYear = DateTime.Now.Year;
            
            // Get bookings for landlord's properties in current month
            var monthlyBookings = await _bookingRepository.GetQueryable()
                .Include(b => b.Property)
                .Where(b => b.Property.OwnerId == userId && 
                           b.StartDate.Month == currentMonth && 
                           b.StartDate.Year == currentYear)
                .ToListAsync();
                
            return monthlyBookings.Sum(b => (double)b.TotalPrice);
        }

        private async Task<double> GetYearlyRevenueAsync(int userId)
        {
            var currentYear = DateTime.Now.Year;
            
            // Get bookings for landlord's properties in current year
            var yearlyBookings = await _bookingRepository.GetQueryable()
                .Include(b => b.Property)
                .Where(b => b.Property.OwnerId == userId && 
                           b.StartDate.Year == currentYear)
                .ToListAsync();
                
            return yearlyBookings.Sum(b => (double)b.TotalPrice);
        }

        private async Task<double> GetAveragePropertyRatingAsync(int userId)
        {
            var properties = await _propertyRepository.GetQueryable()
                .Where(p => p.OwnerId == userId)
                .Include(p => p.Reviews)
                .Where(p => p.Reviews.Any(r => r.StarRating.HasValue))
                .ToListAsync();
                
            if (!properties.Any()) return 0.0;
            
            var totalRating = properties.Sum(p => 
                p.Reviews.Any(r => r.StarRating.HasValue) 
                    ? (double)p.Reviews.Where(r => r.StarRating.HasValue).Average(r => r.StarRating!.Value)
                    : 0.0
            );
            return totalRating / properties.Count;
        }

        private double CalculatePropertyRevenue(Domain.Models.Property property)
        {
            return property.Bookings?.Sum(b => (double)b.TotalPrice) ?? 0.0;
        }

        public async Task<PropertyStatisticsResponse> GetPropertyStatisticsAsync(int userId)
        {
            var allProperties = await _propertyRepository.GetQueryable()
                .Where(p => p.OwnerId == userId)
                .ToListAsync();
                
            var total = allProperties.Count();
            var available = allProperties.Count(p => p.Status == "AVAILABLE");
            var rented = allProperties.Count(p => p.Status == "RENTED");
            double occupancyRate = total > 0 ? (double)rented / total : 0.0;
            
            var vacantPreview = allProperties
                .Where(p => p.Status == "AVAILABLE")
                .Take(5)
                .Select(p => new PropertyMiniSummaryResponse
                {
                    PropertyId = p.PropertyId.ToString(),
                    Title = p.Name,
                    Price = p.Price
                })
                .ToList();
                
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
            // Get property IDs for the landlord
            var propertyIds = await _propertyRepository.GetQueryable()
                .Where(p => p.OwnerId == userId)
                .Select(p => p.PropertyId)
                .ToListAsync();

            var open = await _maintenanceRepository.GetOpenIssuesCountAsync(propertyIds);
            var pending = await _maintenanceRepository.GetPendingIssuesCountAsync(propertyIds);
            var highPriority = await _maintenanceRepository.GetHighPriorityIssuesCountAsync(propertyIds);
            var tenantComplaints = await _maintenanceRepository.GetTenantComplaintsCountAsync(propertyIds);
            
            return new MaintenanceStatisticsResponse
            {
                OpenIssuesCount = open,
                PendingIssuesCount = pending,
                HighPriorityIssuesCount = highPriority,
                TenantComplaintsCount = tenantComplaints
            };
        }

        public async Task<FinancialSummaryResponse> GetFinancialSummaryAsync(int userId, FinancialStatisticsRequest request)
        {
            // Get properties owned by the landlord
            var landlordProperties = await _propertyRepository.GetQueryable()
                .Where(p => p.OwnerId == userId)
                .Include(p => p.MaintenanceIssues)
                .Include(p => p.Bookings)
                .ToListAsync();

            decimal totalRent = 0;
            decimal totalMaintenance = 0;

            // Set default date range if not provided
            var startDate = request.StartDate ?? DateTime.MinValue;
            var endDate = request.EndDate ?? DateTime.MaxValue;
            
            // Convert to DateOnly for booking comparisons
            var startDateOnly = DateOnly.FromDateTime(startDate);
            var endDateOnly = DateOnly.FromDateTime(endDate);

            // Dictionary to track monthly data
            var monthlyData = new Dictionary<(int Year, int Month), (decimal Revenue, decimal Maintenance)>();

            foreach (var property in landlordProperties)
            {
                // Calculate revenue from bookings within date range
                if (property.Bookings != null)
                {
                    var filteredBookings = property.Bookings
                        .Where(b => b.StartDate >= startDateOnly && b.StartDate <= endDateOnly);
                    
                    foreach (var booking in filteredBookings)
                    {
                        totalRent += booking.TotalPrice;
                        
                        // Add to monthly breakdown
                        var bookingDate = booking.StartDate.ToDateTime(TimeOnly.MinValue);
                        var key = (bookingDate.Year, bookingDate.Month);
                        if (!monthlyData.ContainsKey(key))
                            monthlyData[key] = (0m, 0m);
                        var currentData = monthlyData[key];
                        monthlyData[key] = (currentData.Revenue + booking.TotalPrice, currentData.Maintenance);
                    }
                }
                
                // Calculate maintenance costs within date range
                if (property.MaintenanceIssues != null)
                {
                    var filteredMaintenance = property.MaintenanceIssues
                        .Where(m => m.Cost.HasValue && m.CreatedAt >= startDate && m.CreatedAt <= endDate);
                    
                    foreach (var maintenance in filteredMaintenance)
                    {
                        totalMaintenance += maintenance.Cost.Value;
                        
                        // Add to monthly breakdown
                        var key = (maintenance.CreatedAt.Year, maintenance.CreatedAt.Month);
                        if (!monthlyData.ContainsKey(key))
                            monthlyData[key] = (0m, 0m);
                        var currentData = monthlyData[key];
                        monthlyData[key] = (currentData.Revenue, currentData.Maintenance + maintenance.Cost.Value);
                    }
                }
            }

            // Convert monthly data to DTOs and sort by year/month
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
    }
} 