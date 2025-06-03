using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using System.Threading.Tasks;

namespace eRents.Application.Service.StatisticsService // New namespace
{
    public interface IStatisticsService
    {
        Task<PropertyStatisticsResponse> GetPropertyStatisticsAsync(int userId);
        Task<MaintenanceStatisticsResponse> GetMaintenanceStatisticsAsync(int userId);
        Task<FinancialSummaryResponse> GetFinancialSummaryAsync(int userId, FinancialStatisticsRequest request);
        Task<DashboardStatisticsResponse> GetDashboardStatisticsAsync(int userId);
    }
} 