using eRents.Shared.DTO.Response;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace eRents.Application.Services.ReportService
{
    public interface IReportService
    {
        Task<List<FinancialReportResponse>> GetFinancialReportAsync(int userId, DateTime startDate, DateTime endDate);
        Task<List<TenantReportResponse>> GetTenantReportAsync(int userId, DateTime startDate, DateTime endDate);
    }
} 