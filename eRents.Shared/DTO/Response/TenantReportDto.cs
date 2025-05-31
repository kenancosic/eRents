using System;

namespace eRents.Shared.DTO.Response
{
    public class TenantReportDto
    {
        public string LeaseStart { get; set; } = string.Empty;
        public string LeaseEnd { get; set; } = string.Empty;
        public string Tenant { get; set; } = string.Empty;
        public string Property { get; set; } = string.Empty;
        public decimal CostOfRent { get; set; }
        public decimal TotalPaidRent { get; set; }
    }
} 