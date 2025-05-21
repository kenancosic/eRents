using System;

namespace eRents.Shared.DTO.Requests
{
    public class FinancialStatisticsRequest
    {
        public string? Period { get; set; }
        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }
    }
} 