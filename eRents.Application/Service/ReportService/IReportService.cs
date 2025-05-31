using eRents.Shared.DTO.Response;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace eRents.Application.Service.ReportService
{
    public interface IReportService
    {
        Task<List<FinancialReportDto>> GetFinancialReportAsync(int userId, DateTime startDate, DateTime endDate);
        Task<List<TenantReportDto>> GetTenantReportAsync(int userId, DateTime startDate, DateTime endDate);
    }
} 