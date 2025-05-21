using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using System.Threading.Tasks;

namespace eRents.Application.Service.StatisticsService // New namespace
{
    public interface IStatisticsService
    {
        Task<PropertyStatisticsDto> GetPropertyStatisticsAsync();
        Task<MaintenanceStatisticsDto> GetMaintenanceStatisticsAsync();
        Task<FinancialSummaryDto> GetFinancialSummaryAsync(FinancialStatisticsRequest request);
    }
} 