using System;
using System.Collections.Generic;
using eRents.Domain.Shared;

namespace eRents.Domain.Models;

public partial class MaintenanceIssue : BaseEntity
{
    public int MaintenanceIssueId { get; set; }

    public int PropertyId { get; set; }

    public string Title { get; set; } = null!;

    public string? Description { get; set; }

    public int PriorityId { get; set; }

    public int StatusId { get; set; }

    public DateTime CreatedAt { get; set; }

    public DateTime? ResolvedAt { get; set; }

    public decimal? Cost { get; set; }

    public int? AssignedToUserId { get; set; }

    public int ReportedByUserId { get; set; }

    public string? ResolutionNotes { get; set; }

    public string? Category { get; set; }

    public bool RequiresInspection { get; set; }

    public bool IsTenantComplaint { get; set; }

    public virtual Property Property { get; set; } = null!;

    public virtual IssuePriority Priority { get; set; } = null!;

    public virtual IssueStatus Status { get; set; } = null!;

    public virtual User? AssignedToUser { get; set; }

    public virtual User ReportedByUser { get; set; } = null!;

    public virtual ICollection<Image> Images { get; set; } = new List<Image>();
}