using eRents.Domain.Models;
using eRents.Domain.Models.Enums;
using eRents.Features.PropertyManagement.DTOs;

namespace eRents.Features.PropertyManagement.Mappers;

/// <summary>
/// MaintenanceMapper for entity ↔ DTO conversions
/// Clean mapping for reactive maintenance issues only
/// Moved from MaintenanceManagement module during consolidation
/// </summary>
public static class MaintenanceMapper
{
	#region MaintenanceIssue Mappings

	/// <summary>
	/// Convert MaintenanceIssue entity to MaintenanceIssueResponse DTO
	/// </summary>
	public static MaintenanceIssueResponse ToResponse(this MaintenanceIssue issue)
	{
		return new MaintenanceIssueResponse
		{
			MaintenanceIssueId = issue.MaintenanceIssueId,
			PropertyId = issue.PropertyId,
			ReportedByUserId = issue.ReportedByUserId,
			AssignedToUserId = issue.AssignedToUserId,
			Title = issue.Title,
			Description = issue.Description,
			Priority = issue.Priority.ToString(),
			Status = issue.Status.ToString(),
			Cost = issue.Cost,
			ResolvedAt = issue.ResolvedAt,
			ResolutionNotes = issue.ResolutionNotes,
			Category = issue.Category,
			RequiresInspection = issue.RequiresInspection,
			IsTenantComplaint = issue.IsTenantComplaint,
			CreatedAt = issue.CreatedAt,
			UpdatedAt = issue.UpdatedAt
		};
	}

	/// <summary>
	/// Convert MaintenanceIssueRequest DTO to MaintenanceIssue entity
	/// </summary>
	public static MaintenanceIssue ToEntity(this MaintenanceIssueRequest request, int reportedByUserId)
	{
		return new MaintenanceIssue
		{
			PropertyId = request.PropertyId,
			AssignedToUserId = request.AssignedToUserId,
			Title = request.Title,
			Description = request.Description,
			Priority = GetPriorityEnum(request.Priority),
			Status = MaintenanceIssueStatusEnum.Pending, // Default status for new issues
			Cost = request.Cost,
			Category = request.Category,
			RequiresInspection = request.RequiresInspection,
			IsTenantComplaint = request.IsTenantComplaint,
			ResolutionNotes = request.ResolutionNotes,
			ReportedByUserId = reportedByUserId
		};
	}

	/// <summary>
	/// Update MaintenanceIssue entity from MaintenanceIssueRequest DTO
	/// </summary>
	public static void UpdateFromRequest(this MaintenanceIssue issue, MaintenanceIssueRequest request)
	{
		issue.PropertyId = request.PropertyId;
		issue.AssignedToUserId = request.AssignedToUserId;
		issue.Title = request.Title;
		issue.Description = request.Description;
		issue.Priority = GetPriorityEnum(request.Priority);
		issue.Cost = request.Cost;
		issue.Category = request.Category;
		issue.RequiresInspection = request.RequiresInspection;
		issue.IsTenantComplaint = request.IsTenantComplaint;
		issue.ResolutionNotes = request.ResolutionNotes;
	}

	/// <summary>
	/// Update MaintenanceIssue status from MaintenanceStatusUpdateRequest
	/// </summary>
	public static void UpdateStatusFromRequest(this MaintenanceIssue issue, MaintenanceStatusUpdateRequest request)
	{
		issue.Status = GetStatusEnum(request.Status);

		if (request.Cost.HasValue)
			issue.Cost = request.Cost.Value;

		if (request.ResolvedAt.HasValue)
			issue.ResolvedAt = request.ResolvedAt.Value;

		if (!string.IsNullOrEmpty(request.ResolutionNotes))
			issue.ResolutionNotes = request.ResolutionNotes;

		// Auto-set resolution date if status is Completed and no date provided
		if (request.Status.Equals("Completed", StringComparison.OrdinalIgnoreCase) && !issue.ResolvedAt.HasValue)
			issue.ResolvedAt = DateTime.UtcNow;
	}

	/// <summary>
	/// Convert list of MaintenanceIssue entities to MaintenanceIssueResponse DTOs
	/// </summary>
	public static List<MaintenanceIssueResponse> ToResponseList(this IEnumerable<MaintenanceIssue> issues)
	{
		return issues.Select(i => i.ToResponse()).ToList();
	}

	#endregion

	#region Statistics Mappings

	/// <summary>
	/// Create MaintenanceStatisticsResponse from aggregated data
	/// </summary>
	public static MaintenanceStatisticsResponse ToStatisticsResponse(
			int totalIssues,
			int pendingIssues,
			int inProgressIssues,
			int completedIssues,
			int highPriorityIssues,
			int emergencyIssues,
			decimal totalCosts,
			double averageResolutionDays,
			int tenantComplaints,
			int issuesRequiringInspection,
			DateTime? oldestPendingIssue)
	{
		return new MaintenanceStatisticsResponse
		{
			TotalIssues = totalIssues,
			PendingIssues = pendingIssues,
			InProgressIssues = inProgressIssues,
			CompletedIssues = completedIssues,
			HighPriorityIssues = highPriorityIssues,
			EmergencyIssues = emergencyIssues,
			TotalCosts = totalCosts,
			AverageCostPerIssue = totalIssues > 0 ? totalCosts / totalIssues : 0,
			AverageResolutionDays = averageResolutionDays,
			TenantComplaints = tenantComplaints,
			IssuesRequiringInspection = issuesRequiringInspection,
			OldestPendingIssue = oldestPendingIssue
		};
	}

	/// <summary>
	/// Create PropertyMaintenanceSummaryResponse from aggregated data
	/// </summary>
	public static PropertyMaintenanceSummaryResponse ToPropertySummaryResponse(
			int propertyId,
			int totalIssues,
			int pendingIssues,
			decimal totalCosts,
			DateTime? lastResolvedDate,
			int tenantComplaints,
			int issuesRequiringInspection)
	{
		return new PropertyMaintenanceSummaryResponse
		{
			PropertyId = propertyId,
			TotalIssues = totalIssues,
			PendingIssues = pendingIssues,
			TotalCosts = totalCosts,
			LastResolvedDate = lastResolvedDate,
			TenantComplaints = tenantComplaints,
			IssuesRequiringInspection = issuesRequiringInspection
		};
	}

	#endregion

	#region Helper Methods

	/// <summary>
	/// Get priority enum from priority name
	/// </summary>
	private static MaintenanceIssuePriorityEnum GetPriorityEnum(string priority)
	{
		return priority.ToLower() switch
		{
			"low" => MaintenanceIssuePriorityEnum.Low,
			"medium" => MaintenanceIssuePriorityEnum.Medium,
			"high" => MaintenanceIssuePriorityEnum.High,
			"emergency" => MaintenanceIssuePriorityEnum.Emergency,
			_ => MaintenanceIssuePriorityEnum.Medium
		};
	}

	/// <summary>
	/// Get status enum from status name
	/// </summary>
	private static MaintenanceIssueStatusEnum GetStatusEnum(string status)
	{
		return status.ToLower() switch
		{
			"pending" => MaintenanceIssueStatusEnum.Pending,
			"inprogress" => MaintenanceIssueStatusEnum.InProgress,
			"completed" => MaintenanceIssueStatusEnum.Completed,
			"cancelled" => MaintenanceIssueStatusEnum.Cancelled,
			_ => MaintenanceIssueStatusEnum.Pending
		};
	}

	#endregion
}