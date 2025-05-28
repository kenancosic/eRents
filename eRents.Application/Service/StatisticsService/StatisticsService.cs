using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using System.Threading.Tasks;
using System.Collections.Generic; // For List in PropertyStatisticsDto placeholder
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

        public async Task<DashboardStatisticsDto> GetDashboardStatisticsAsync(string userId)
        {
            var propertyStats = await GetPropertyStatisticsAsync(userId);
            var maintenanceStats = await GetMaintenanceStatisticsAsync(userId);
            var financialStats = await GetFinancialSummaryAsync(userId, new FinancialStatisticsRequest());
            var topProperties = await GetTopPropertiesAsync(userId);
            var monthlyRevenue = await GetMonthlyRevenueAsync(userId);
            var yearlyRevenue = await GetYearlyRevenueAsync(userId);
            var averageRating = await GetAveragePropertyRatingAsync(userId);

            return new DashboardStatisticsDto
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

        private async Task<List<PopularPropertyDto>> GetTopPropertiesAsync(string userId)
        {
            var properties = await _propertyRepository.GetQueryable()
                .Where(p => p.OwnerId.ToString() == userId)
                .Include(p => p.Bookings)
                .Include(p => p.Reviews)
                .OrderByDescending(p => p.Bookings.Count())
                .Take(5)
                .ToListAsync();

            return properties.Select(p => new PopularPropertyDto
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

        private async Task<double> GetMonthlyRevenueAsync(string userId)
        {
            var currentMonth = DateTime.Now.Month;
            var currentYear = DateTime.Now.Year;
            var monthlyBookings = await _bookingRepository.GetQueryable()
                .Where(b => b.UserId.ToString() == userId && b.StartDate.Month == currentMonth && b.StartDate.Year == currentYear)
                .ToListAsync();
            return monthlyBookings.Sum(b => (double)b.TotalPrice);
        }

        private async Task<double> GetYearlyRevenueAsync(string userId)
        {
            var currentYear = DateTime.Now.Year;
            var yearlyBookings = await _bookingRepository.GetQueryable()
                .Where(b => b.UserId.ToString() == userId && b.StartDate.Year == currentYear)
                .ToListAsync();
            return yearlyBookings.Sum(b => (double)b.TotalPrice);
        }

        private async Task<double> GetAveragePropertyRatingAsync(string userId)
        {
            var properties = await _propertyRepository.GetQueryable()
                .Where(p => p.OwnerId.ToString() == userId)
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

        public async Task<PropertyStatisticsDto> GetPropertyStatisticsAsync(string userId)
        {
            var allProperties = await _propertyRepository.GetQueryable()
                .Where(p => p.OwnerId.ToString() == userId)
                .ToListAsync();
            var total = allProperties.Count();
            var available = allProperties.Count(p => p.Status == "AVAILABLE");
            var rented = allProperties.Count(p => p.Status == "RENTED");
            double occupancyRate = total > 0 ? (double)rented / total : 0.0;
            var vacantPreview = allProperties
                .Where(p => p.Status == "AVAILABLE")
                .Take(5)
                .Select(p => new PropertyMiniSummaryDto
                {
                    PropertyId = p.PropertyId.ToString(),
                    Title = p.Name,
                    Price = p.Price
                })
                .ToList();
            return new PropertyStatisticsDto
            {
                TotalProperties = total,
                AvailableUnits = available,
                RentedUnits = rented,
                OccupancyRate = occupancyRate,
                VacantPropertiesPreview = vacantPreview
            };
        }

        public async Task<MaintenanceStatisticsDto> GetMaintenanceStatisticsAsync(string userId)
        {
            // For maintenance, filter by properties owned by user
            var propertyIds = await _propertyRepository.GetQueryable()
                .Where(p => p.OwnerId.ToString() == userId)
                .Select(p => p.PropertyId)
                .ToListAsync();
            var open = await _maintenanceRepository.GetOpenIssuesCountAsync(propertyIds);
            var pending = await _maintenanceRepository.GetPendingIssuesCountAsync(propertyIds);
            var highPriority = await _maintenanceRepository.GetHighPriorityIssuesCountAsync(propertyIds);
            var tenantComplaints = await _maintenanceRepository.GetTenantComplaintsCountAsync(propertyIds);
            return new MaintenanceStatisticsDto
            {
                OpenIssuesCount = open,
                PendingIssuesCount = pending,
                HighPriorityIssuesCount = highPriority,
                TenantComplaintsCount = tenantComplaints
            };
        }

        public async Task<FinancialSummaryDto> GetFinancialSummaryAsync(string userId, FinancialStatisticsRequest request)
        {
            var allProperties = await _propertyRepository.GetQueryable()
                .Where(p => p.OwnerId.ToString() == userId)
                .Include(p => p.MaintenanceIssues)
                .ToListAsync();
            decimal totalRent = 0;
            decimal totalMaintenance = 0;
            foreach (var property in allProperties)
            {
                totalRent += await _propertyRepository.GetTotalRevenueAsync(property.PropertyId);
                if (property.MaintenanceIssues != null)
                {
                    totalMaintenance += property.MaintenanceIssues.Where(m => m.Cost.HasValue).Sum(m => m.Cost.Value);
                }
            }
            return new FinancialSummaryDto
            {
                TotalRentIncome = totalRent,
                TotalMaintenanceCosts = totalMaintenance,
                OtherIncome = 0,
                OtherExpenses = 0,
                NetTotal = totalRent - totalMaintenance
            };
        }
    }
} 