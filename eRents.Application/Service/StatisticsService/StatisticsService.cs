using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using System.Threading.Tasks;
using System.Collections.Generic; // For List in PropertyStatisticsDto placeholder
using eRents.Domain.Repositories;

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

        public async Task<PropertyStatisticsDto> GetPropertyStatisticsAsync()
        {
            var allProperties = await _propertyRepository.GetAllAsync();
            var total = allProperties.Count();
            var available = allProperties.Count(p => p.Status != null && p.Status.StatusName == "Available");
            var rented = allProperties.Count(p => p.Status != null && p.Status.StatusName == "Rented");
            double occupancyRate = total > 0 ? (double)rented / total : 0.0;

            var vacantPreview = allProperties
                .Where(p => p.Status != null && p.Status.StatusName == "Available")
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

        public async Task<MaintenanceStatisticsDto> GetMaintenanceStatisticsAsync()
        {
            var open = await _maintenanceRepository.GetOpenIssuesCountAsync();
            var pending = await _maintenanceRepository.GetPendingIssuesCountAsync();
            var highPriority = await _maintenanceRepository.GetHighPriorityIssuesCountAsync();
            var tenantComplaints = await _maintenanceRepository.GetTenantComplaintsCountAsync();

            return new MaintenanceStatisticsDto
            {
                OpenIssuesCount = open,
                PendingIssuesCount = pending,
                HighPriorityIssuesCount = highPriority,
                TenantComplaintsCount = tenantComplaints
            };
        }

        public async Task<FinancialSummaryDto> GetFinancialSummaryAsync(FinancialStatisticsRequest request)
        {
            // For demo: sum all bookings as rent income, sum all maintenance costs
            var allProperties = await _propertyRepository.GetAllAsync();
            decimal totalRent = 0;
            decimal totalMaintenance = 0;

            foreach (var property in allProperties)
            {
                totalRent += await _propertyRepository.GetTotalRevenueAsync(property.PropertyId);
                // Sum maintenance costs for this property
                if (property.MaintenanceIssues != null)
                {
                    totalMaintenance += property.MaintenanceIssues.Where(m => m.Cost.HasValue).Sum(m => m.Cost.Value);
                }
            }

            // OtherIncome/OtherExpenses can be extended as needed
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