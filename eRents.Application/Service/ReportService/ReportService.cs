using eRents.Domain.Repositories;
using eRents.Shared.DTO.Response;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Threading.Tasks;

namespace eRents.Application.Service.ReportService
{
    public class ReportService : IReportService
    {
        private readonly IPropertyRepository _propertyRepository;
        private readonly IBookingRepository _bookingRepository;
        private readonly IMaintenanceRepository _maintenanceRepository;
        private readonly IUserRepository _userRepository;

        public ReportService(
            IPropertyRepository propertyRepository,
            IBookingRepository bookingRepository,
            IMaintenanceRepository maintenanceRepository,
            IUserRepository userRepository)
        {
            _propertyRepository = propertyRepository;
            _bookingRepository = bookingRepository;
            _maintenanceRepository = maintenanceRepository;
            _userRepository = userRepository;
        }

        public async Task<List<FinancialReportResponse>> GetFinancialReportAsync(int userId, DateTime startDate, DateTime endDate)
        {
            // Convert DateTime to DateOnly for comparison
            var startDateOnly = DateOnly.FromDateTime(startDate);
            var endDateOnly = DateOnly.FromDateTime(endDate);

            // Get all properties owned by the landlord
            var landlordProperties = await _propertyRepository.GetQueryable()
                .Where(p => p.OwnerId == userId)
                .Include(p => p.Bookings)
                .Include(p => p.MaintenanceIssues)
                .ToListAsync();

            var financialReports = new List<FinancialReportResponse>();

            foreach (var property in landlordProperties)
            {
                // Calculate rental income within the date range
                var periodBookings = property.Bookings?
                    .Where(b => b.StartDate >= startDateOnly && b.StartDate <= endDateOnly)
                    .ToList() ?? new List<Domain.Models.Booking>();

                var totalRent = periodBookings.Sum(b => b.TotalPrice);

                // Calculate maintenance costs within the date range
                var periodMaintenance = property.MaintenanceIssues?
                    .Where(m => m.CreatedAt >= startDate && m.CreatedAt <= endDate && m.Cost.HasValue)
                    .ToList() ?? new List<Domain.Models.MaintenanceIssue>();

                var maintenanceCosts = periodMaintenance.Sum(m => m.Cost ?? 0);

                // Only include properties that had activity in the period
                if (totalRent > 0 || maintenanceCosts > 0)
                {
                    financialReports.Add(new FinancialReportResponse
                    {
                        DateFrom = startDate.ToString("dd/MM/yyyy"),
                        DateTo = endDate.ToString("dd/MM/yyyy"),
                        Property = property.Name,
                        TotalRent = totalRent,
                        MaintenanceCosts = maintenanceCosts,
                        Total = totalRent - maintenanceCosts
                    });
                }
            }

            return financialReports.OrderBy(r => r.Property).ToList();
        }

        public async Task<List<TenantReportResponse>> GetTenantReportAsync(int userId, DateTime startDate, DateTime endDate)
        {
            // Convert DateTime to DateOnly for comparison
            var startDateOnly = DateOnly.FromDateTime(startDate);
            var endDateOnly = DateOnly.FromDateTime(endDate);

            // Get all bookings for landlord's properties within the date range
            var tenantReports = await _bookingRepository.GetQueryable()
                .Include(b => b.Property)
                .Include(b => b.User)
                .Where(b => b.Property!.OwnerId == userId &&
                           b.StartDate >= startDateOnly && b.StartDate <= endDateOnly)
                .Select(b => new TenantReportResponse
                {
                    LeaseStart = b.StartDate.ToString("dd/MM/yyyy"),
                    LeaseEnd = b.EndDate.HasValue ? b.EndDate.Value.ToString("dd/MM/yyyy") : "Ongoing",
                    Tenant = b.User!.FirstName + " " + b.User.LastName,
                    Property = b.Property!.Name,
                    CostOfRent = b.TotalPrice,
                    TotalPaidRent = b.TotalPrice // For simplicity, assuming full payment
                })
                .ToListAsync();

            return tenantReports.OrderBy(r => r.Tenant).ThenBy(r => r.Property).ToList();
        }
    }
} 