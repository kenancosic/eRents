using System;
using eRents.Shared.DTO.Base;

namespace eRents.Shared.DTO.Response
{
    public class FinancialReportResponse : BaseResponse
    {
        public string DateFrom { get; set; } = string.Empty;
        public string DateTo { get; set; } = string.Empty;
        public string Property { get; set; } = string.Empty;
        public decimal TotalRent { get; set; }
        public decimal MaintenanceCosts { get; set; }
        public decimal Total { get; set; }
    }
} 