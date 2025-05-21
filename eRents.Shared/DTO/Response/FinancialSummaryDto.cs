using System;

namespace eRents.Shared.DTO.Response
{
    public class FinancialSummaryDto
    {
        public decimal TotalRentIncome { get; set; }
        public decimal TotalMaintenanceCosts { get; set; }
        public decimal OtherIncome { get; set; }
        public decimal OtherExpenses { get; set; }
        public decimal NetTotal { get; set; }
    }
} 