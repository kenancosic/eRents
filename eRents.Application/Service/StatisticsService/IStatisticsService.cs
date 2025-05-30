using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using System.Threading.Tasks;

namespace eRents.Application.Service.StatisticsService // New namespace
{
    public interface IStatisticsService
    {
        Task<PropertyStatisticsDto> GetPropertyStatisticsAsync(int userId);
        Task<MaintenanceStatisticsDto> GetMaintenanceStatisticsAsync(int userId);
        Task<FinancialSummaryDto> GetFinancialSummaryAsync(int userId, FinancialStatisticsRequest request);
        Task<DashboardStatisticsDto> GetDashboardStatisticsAsync(int userId);
    }
} 