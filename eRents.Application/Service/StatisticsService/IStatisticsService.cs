using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using System.Threading.Tasks;

namespace eRents.Application.Service.StatisticsService // New namespace
{
    public interface IStatisticsService
    {
        Task<PropertyStatisticsDto> GetPropertyStatisticsAsync(string userId);
        Task<MaintenanceStatisticsDto> GetMaintenanceStatisticsAsync(string userId);
        Task<FinancialSummaryDto> GetFinancialSummaryAsync(string userId, FinancialStatisticsRequest request);
        Task<DashboardStatisticsDto> GetDashboardStatisticsAsync(string userId);
    }
} 