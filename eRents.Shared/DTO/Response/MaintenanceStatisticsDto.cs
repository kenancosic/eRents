namespace eRents.Shared.DTO.Response
{
    public class MaintenanceStatisticsDto
    {
        public int OpenIssuesCount { get; set; }
        public int PendingIssuesCount { get; set; }
        public int HighPriorityIssuesCount { get; set; }
        public int TenantComplaintsCount { get; set; }
    }
} 