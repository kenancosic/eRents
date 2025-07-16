using System.ComponentModel.DataAnnotations;

namespace eRents.Features.MaintenanceManagement.DTOs;

/// <summary>
/// MaintenanceManagement DTOs - Clean DTOs with foreign key IDs only
/// Following modular architecture principles - Reactive Issues Only
/// </summary>

#region Maintenance Issue DTOs

/// <summary>
/// Response DTO for MaintenanceIssue entity
/// </summary>
public class MaintenanceIssueResponse
{
    public int MaintenanceIssueId { get; set; }
    public int PropertyId { get; set; }
    public int ReportedByUserId { get; set; }
    public int? AssignedToUserId { get; set; }
    
    [Required]
    public string Title { get; set; } = string.Empty;
    
    public string? Description { get; set; }
    
    [Required]
    public string Priority { get; set; } = string.Empty; // Low, Medium, High, Emergency
    
    [Required]
    public string Status { get; set; } = string.Empty; // Pending, InProgress, Completed, Cancelled
    
    public decimal? Cost { get; set; }
    public DateTime? ResolvedAt { get; set; }
    public string? ResolutionNotes { get; set; }
    public string? Category { get; set; }
    public bool RequiresInspection { get; set; }
    public bool IsTenantComplaint { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}

/// <summary>
/// Request DTO for creating/updating MaintenanceIssue
/// </summary>
public class MaintenanceIssueRequest
{
    [Required]
    public int PropertyId { get; set; }
    
    public int? AssignedToUserId { get; set; }
    
    [Required]
    [StringLength(200)]
    public string Title { get; set; } = string.Empty;
    
    [StringLength(1000)]
    public string? Description { get; set; }
    
    [Required]
    public string Priority { get; set; } = "Medium"; // Low, Medium, High, Emergency
    
    public decimal? Cost { get; set; }
    public string? Category { get; set; }
    public bool RequiresInspection { get; set; }
    public bool IsTenantComplaint { get; set; }
    
    [StringLength(500)]
    public string? ResolutionNotes { get; set; }
}

/// <summary>
/// DTO for updating maintenance issue status
/// </summary>
public class MaintenanceStatusUpdateRequest
{
    [Required]
    public string Status { get; set; } = string.Empty;
    
    public decimal? Cost { get; set; }
    public DateTime? ResolvedAt { get; set; }
    
    [StringLength(500)]
    public string? ResolutionNotes { get; set; }
}

/// <summary>
/// DTO for maintenance assignment requests
/// </summary>
public class AssignMaintenanceRequest
{
    [Required]
    public int AssignedToUserId { get; set; }
}

/// <summary>
/// DTO for bulk completion requests
/// </summary>
public class BulkCompleteRequest
{
    [Required]
    [MinLength(1, ErrorMessage = "At least one issue ID is required")]
    public List<int> IssueIds { get; set; } = new();
    
    [StringLength(500)]
    public string? ResolutionNotes { get; set; }
}

#endregion

#region Summary and Statistics DTOs

/// <summary>
/// DTO for maintenance statistics and summary
/// </summary>
public class MaintenanceStatisticsResponse
{
    public int TotalIssues { get; set; }
    public int PendingIssues { get; set; }
    public int InProgressIssues { get; set; }
    public int CompletedIssues { get; set; }
    public int HighPriorityIssues { get; set; }
    public int EmergencyIssues { get; set; }
    public decimal TotalCosts { get; set; }
    public decimal AverageCostPerIssue { get; set; }
    public double AverageResolutionDays { get; set; }
    public int TenantComplaints { get; set; }
    public int IssuesRequiringInspection { get; set; }
    public DateTime? OldestPendingIssue { get; set; }
}

/// <summary>
/// DTO for property maintenance summary
/// </summary>
public class PropertyMaintenanceSummaryResponse
{
    public int PropertyId { get; set; }
    public int TotalIssues { get; set; }
    public int PendingIssues { get; set; }
    public decimal TotalCosts { get; set; }
    public DateTime? LastResolvedDate { get; set; }
    public int TenantComplaints { get; set; }
    public int IssuesRequiringInspection { get; set; }
}

#endregion
