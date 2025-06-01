using System;
using System.Collections.Generic;

namespace eRents.Shared.DTO.Response
{
    public class FinancialSummaryDto
    {
        public decimal TotalRentIncome { get; set; }
        public decimal TotalMaintenanceCosts { get; set; }
        public decimal OtherIncome { get; set; }
        public decimal OtherExpenses { get; set; }
        public decimal NetTotal { get; set; }
        
        // Enhanced for monthly breakdown
        public List<MonthlyRevenueDto> RevenueHistory { get; set; } = new List<MonthlyRevenueDto>();
    }

    public class MonthlyRevenueDto
    {
        public int Year { get; set; }
        public int Month { get; set; }
        public decimal Revenue { get; set; }
        public decimal MaintenanceCosts { get; set; }
    }
} 