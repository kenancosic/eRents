using eRents.Domain.Models.Enums;

namespace eRents.Features.MaintenanceManagement.Models
{
    public class MaintenanceIssueRequest
    {
        public int PropertyId { get; set; }
        public string Title { get; set; } = string.Empty;
        public string? Description { get; set; }
        public MaintenanceIssuePriorityEnum Priority { get; set; } = MaintenanceIssuePriorityEnum.Medium;
        public MaintenanceIssueStatusEnum Status { get; set; } = MaintenanceIssueStatusEnum.Pending;
        public decimal? Cost { get; set; }
        public int? AssignedToUserId { get; set; }
        public int ReportedByUserId { get; set; }
        public string? ResolutionNotes { get; set; }
        public bool IsTenantComplaint { get; set; }
        public int[]? ImageIds { get; set; }
    }
}
