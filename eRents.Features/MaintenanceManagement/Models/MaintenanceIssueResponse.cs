using System;
using eRents.Domain.Models.Enums;

namespace eRents.Features.MaintenanceManagement.Models
{
    public class MaintenanceIssueResponse
    {
        public int MaintenanceIssueId { get; set; }
        public int PropertyId { get; set; }
        public string Title { get; set; } = string.Empty;
        public string? Description { get; set; }
        public MaintenanceIssuePriorityEnum Priority { get; set; }
        public MaintenanceIssueStatusEnum Status { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? ResolvedAt { get; set; }
        public decimal? Cost { get; set; }
        public int? AssignedToUserId { get; set; }
        public int ReportedByUserId { get; set; }
        public string? ResolutionNotes { get; set; }
        public bool IsTenantComplaint { get; set; }
        public int[] ImageIds { get; set; } = Array.Empty<int>();

        // Expose severity weight for sorting on client
        public int PrioritySeverity => Priority switch
        {
            MaintenanceIssuePriorityEnum.Emergency => 4,
            MaintenanceIssuePriorityEnum.High => 3,
            MaintenanceIssuePriorityEnum.Medium => 2,
            MaintenanceIssuePriorityEnum.Low => 1,
            _ => 0
        };
    }
}
