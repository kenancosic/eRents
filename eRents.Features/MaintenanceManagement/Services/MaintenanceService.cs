using eRents.Domain.Models;
using eRents.Domain.Models.Enums;
using eRents.Domain.Shared;
using eRents.Domain.Shared.Interfaces;
using eRents.Features.MaintenanceManagement.DTOs;
using eRents.Features.MaintenanceManagement.Mappers;
using eRents.Features.Shared.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace eRents.Features.MaintenanceManagement.Services;

/// <summary>
/// MaintenanceService for reactive maintenance issues only
/// Handles maintenance issues, requests, and tracking
/// </summary>
public class MaintenanceService : BaseService, IMaintenanceService
{
	public MaintenanceService(
			ERentsContext context,
			IUnitOfWork unitOfWork,
			ICurrentUserService currentUserService,
			ILogger<MaintenanceService> logger)
		: base(context, unitOfWork, currentUserService, logger)
	{
	}

	#region Maintenance Issue CRUD

	/// <summary>
	/// Get maintenance issue by ID
	/// </summary>
	public async Task<MaintenanceIssueResponse?> GetMaintenanceIssueByIdAsync(int id)
	{
		return await GetByIdAsync<MaintenanceIssue, MaintenanceIssueResponse>(
			id,
			q => q.Include(m => m.Property).Include(m => m.Status).Include(m => m.Priority).AsNoTracking(),
			async issue => await CanAccessIssueAsync(issue),
			issue => issue.ToResponse(),
			"GetMaintenanceIssueById"
		);
	}

	/// <summary>
	/// Get maintenance issues for current user with filtering
	/// </summary>
	public async Task<List<MaintenanceIssueResponse>> GetUserMaintenanceIssuesAsync(
			int? propertyId = null,
			string? status = null,
			string? priority = null,
			DateTime? startDate = null,
			DateTime? endDate = null)
	{
		try
		{
			var query = Context.MaintenanceIssues
					.Where(m => m.Property.OwnerId == CurrentUserId || m.AssignedToUserId == CurrentUserId);

			// Apply filters
			if (propertyId.HasValue)
				query = query.Where(m => m.PropertyId == propertyId.Value);

			if (!string.IsNullOrEmpty(status))
			{
				var statusId = GetStatusId(status);
				query = query.Where(m => m.StatusId == statusId);
			}

			if (!string.IsNullOrEmpty(priority))
			{
				var priorityId = GetPriorityId(priority);
				query = query.Where(m => m.PriorityId == priorityId);
			}

			if (startDate.HasValue)
				query = query.Where(m => m.CreatedAt >= startDate.Value);

			if (endDate.HasValue)
				query = query.Where(m => m.CreatedAt <= endDate.Value);

			var issues = await query
					.Include(m => m.Property)
					.Include(m => m.Status)
					.Include(m => m.Priority)
					.OrderByDescending(m => m.CreatedAt)
					.AsNoTracking()
					.ToListAsync();

			return issues.ToResponseList();
		}
		catch (Exception ex)
		{
			LogError(ex, "Error retrieving user maintenance issues");
			throw;
		}
	}

	/// <summary>
	/// Get maintenance issues for specific property
	/// </summary>
	public async Task<List<MaintenanceIssueResponse>> GetPropertyMaintenanceIssuesAsync(int propertyId)
	{
		try
		{
			// Verify property ownership
			var property = await Context.Properties
					.FirstOrDefaultAsync(p => p.PropertyId == propertyId && p.OwnerId == CurrentUserId);

			if (property == null)
				throw new UnauthorizedAccessException("Property not found or access denied");

			var issues = await Context.MaintenanceIssues
					.Where(m => m.PropertyId == propertyId)
					.Include(m => m.Status)
					.Include(m => m.Priority)
					.OrderByDescending(m => m.CreatedAt)
					.AsNoTracking()
					.ToListAsync();

			return issues.ToResponseList();
		}
		catch (Exception ex)
		{
			LogError(ex, "Error retrieving maintenance issues for property {PropertyId}", propertyId);
			throw;
		}
	}

	/// <summary>
	/// Create new maintenance issue
	/// </summary>
	public async Task<MaintenanceIssueResponse> CreateMaintenanceIssueAsync(MaintenanceIssueRequest request)
	{
		return await CreateAsync<MaintenanceIssue, MaintenanceIssueRequest, MaintenanceIssueResponse>(
			request,
			req => req.ToEntity(CurrentUserId),
			async (entity, req) => await ValidatePropertyOwnershipAsync(req.PropertyId),
			entity => {
				// Load navigation properties for proper response mapping
				Context.Entry(entity).Reference(m => m.Status).Load();
				Context.Entry(entity).Reference(m => m.Priority).Load();
				return entity.ToResponse();
			},
			"CreateMaintenanceIssue"
		);
	}

	/// <summary>
	/// Update existing maintenance issue
	/// </summary>
	public async Task<MaintenanceIssueResponse> UpdateMaintenanceIssueAsync(int id, MaintenanceIssueRequest request)
	{
		return await UpdateAsync<MaintenanceIssue, MaintenanceIssueRequest, MaintenanceIssueResponse>(
			id,
			request,
			q => q.Include(m => m.Property).Include(m => m.Status).Include(m => m.Priority),
			async issue => await CanUpdateIssueAsync(issue),
			async (entity, req) => {
				entity.UpdateFromRequest(req);
				await Task.CompletedTask;
			},
			entity => entity.ToResponse(),
			"UpdateMaintenanceIssue"
		);
	}

	/// <summary>
	/// Update maintenance issue status
	/// </summary>
	public async Task UpdateMaintenanceStatusAsync(int id, MaintenanceStatusUpdateRequest request)
	{
		try
		{
			var issue = await Context.MaintenanceIssues
					.Include(m => m.Property)
					.FirstOrDefaultAsync(m => m.MaintenanceIssueId == id);

			if (issue == null)
				throw new ArgumentException("Maintenance issue not found");

			// Verify access rights - owner or assigned user can update status
			if (issue.Property.OwnerId != CurrentUserId && issue.AssignedToUserId != CurrentUserId)
				throw new UnauthorizedAccessException("Access denied to this maintenance issue");

			issue.UpdateStatusFromRequest(request);

			await UnitOfWork.SaveChangesAsync();

			LogInfo("Updated maintenance issue {IssueId} status to {Status}", id, request.Status);
		}
		catch (Exception ex)
		{
			LogError(ex, "Error updating maintenance issue {IssueId} status", id);
			throw;
		}
	}

	/// <summary>
	/// Delete maintenance issue
	/// </summary>
	public async Task DeleteMaintenanceIssueAsync(int id)
	{
		await DeleteAsync<MaintenanceIssue>(
			id,
			async issue => {
				await Context.Entry(issue).Reference(m => m.Property).LoadAsync();
				return await CanDeleteIssueAsync(issue);
			},
			"DeleteMaintenanceIssue"
		);
	}

	#endregion

	#region Maintenance Statistics

	/// <summary>
	/// Get maintenance statistics for current user
	/// </summary>
	public async Task<MaintenanceStatisticsResponse> GetMaintenanceStatisticsAsync()
	{
		try
		{
			var userPropertyIds = await Context.Properties
					.Where(p => p.OwnerId == CurrentUserId)
					.Select(p => p.PropertyId)
					.ToListAsync();

			var issues = await Context.MaintenanceIssues
					.Where(m => userPropertyIds.Contains(m.PropertyId))
					.Include(m => m.Status)
					.Include(m => m.Priority)
					.AsNoTracking()
					.ToListAsync();

			var totalIssues = issues.Count;
			var pendingIssues = issues.Count(i => i.Status.StatusName == "Pending");
			var inProgressIssues = issues.Count(i => i.Status.StatusName == "InProgress");
			var completedIssues = issues.Count(i => i.Status.StatusName == "Completed");
			var highPriorityIssues = issues.Count(i => i.Priority.PriorityName == "High");
			var emergencyIssues = issues.Count(i => i.Priority.PriorityName == "Emergency");
			var totalCosts = issues.Where(i => i.Cost.HasValue).Sum(i => i.Cost!.Value);

			// Calculate average resolution days for completed issues
			var completedWithDates = issues.Where(i => i.Status.StatusName == "Completed" && i.ResolvedAt.HasValue).ToList();
			var averageResolutionDays = completedWithDates.Any()
					? completedWithDates.Average(i => (i.ResolvedAt!.Value - i.CreatedAt).TotalDays)
					: 0;

			var tenantComplaints = issues.Count(i => i.IsTenantComplaint);
			var issuesRequiringInspection = issues.Count(i => i.RequiresInspection);
			var oldestPendingIssue = issues.Where(i => i.Status.StatusName == "Pending").OrderBy(i => i.CreatedAt).FirstOrDefault()?.CreatedAt;

			return MaintenanceMapper.ToStatisticsResponse(
					totalIssues, pendingIssues, inProgressIssues, completedIssues, highPriorityIssues, emergencyIssues,
					totalCosts, averageResolutionDays, tenantComplaints, issuesRequiringInspection, oldestPendingIssue);
		}
		catch (Exception ex)
		{
			LogError(ex, "Error retrieving maintenance statistics");
			throw;
		}
	}

	/// <summary>
	/// Get maintenance summary for specific property
	/// </summary>
	public async Task<PropertyMaintenanceSummaryResponse> GetPropertyMaintenanceSummaryAsync(int propertyId)
	{
		try
		{
			// Verify property ownership
			var property = await Context.Properties
					.FirstOrDefaultAsync(p => p.PropertyId == propertyId && p.OwnerId == CurrentUserId);

			if (property == null)
				throw new UnauthorizedAccessException("Property not found or access denied");

			var issues = await Context.MaintenanceIssues
					.Where(m => m.PropertyId == propertyId)
					.Include(m => m.Status)
					.AsNoTracking()
					.ToListAsync();

			var totalIssues = issues.Count;
			var pendingIssues = issues.Count(i => i.Status.StatusName == "Pending");
			var totalCosts = issues.Where(i => i.Cost.HasValue).Sum(i => i.Cost!.Value);
			var lastResolvedDate = issues.Where(i => i.ResolvedAt.HasValue).OrderByDescending(i => i.ResolvedAt).FirstOrDefault()?.ResolvedAt;
			var tenantComplaints = issues.Count(i => i.IsTenantComplaint);
			var issuesRequiringInspection = issues.Count(i => i.RequiresInspection);

			return MaintenanceMapper.ToPropertySummaryResponse(
					propertyId, totalIssues, pendingIssues, totalCosts, lastResolvedDate, tenantComplaints, issuesRequiringInspection);
		}
		catch (Exception ex)
		{
			LogError(ex, "Error retrieving maintenance summary for property {PropertyId}", propertyId);
			throw;
		}
	}

	/// <summary>
	/// Get overdue maintenance issues (pending issues older than 7 days)
	/// </summary>
	public async Task<List<MaintenanceIssueResponse>> GetOverdueMaintenanceIssuesAsync()
	{
		try
		{
			var overdueThreshold = DateTime.UtcNow.AddDays(-7);

			var userPropertyIds = await Context.Properties
					.Where(p => p.OwnerId == CurrentUserId)
					.Select(p => p.PropertyId)
					.ToListAsync();

			var overdueIssues = await Context.MaintenanceIssues
					.Where(m => userPropertyIds.Contains(m.PropertyId) &&
										 m.Status.StatusName == "Pending" &&
										 m.CreatedAt < overdueThreshold)
					.Include(m => m.Status)
					.Include(m => m.Priority)
					.OrderBy(m => m.CreatedAt)
					.AsNoTracking()
					.ToListAsync();

			return overdueIssues.ToResponseList();
		}
		catch (Exception ex)
		{
			LogError(ex, "Error retrieving overdue maintenance issues");
			throw;
		}
	}

	/// <summary>
	/// Get recent maintenance issues (last 7 days)
	/// </summary>
	public async Task<List<MaintenanceIssueResponse>> GetUpcomingMaintenanceAsync(int days = 7)
	{
		try
		{
			var recentThreshold = DateTime.UtcNow.AddDays(-days);

			var userPropertyIds = await Context.Properties
					.Where(p => p.OwnerId == CurrentUserId)
					.Select(p => p.PropertyId)
					.ToListAsync();

			var recentIssues = await Context.MaintenanceIssues
					.Where(m => userPropertyIds.Contains(m.PropertyId) &&
										 m.CreatedAt >= recentThreshold)
					.Include(m => m.Status)
					.Include(m => m.Priority)
					.OrderByDescending(m => m.CreatedAt)
					.AsNoTracking()
					.ToListAsync();

			return recentIssues.ToResponseList();
		}
		catch (Exception ex)
		{
			LogError(ex, "Error retrieving recent maintenance issues");
			throw;
		}
	}

	#endregion

	#region Maintenance Assignment

	/// <summary>
	/// Assign maintenance issue to user
	/// </summary>
	public async Task AssignMaintenanceIssueAsync(int issueId, int assignedToUserId)
	{
		try
		{
			var issue = await Context.MaintenanceIssues
					.Include(m => m.Property)
					.FirstOrDefaultAsync(m => m.MaintenanceIssueId == issueId);

			if (issue == null)
				throw new ArgumentException("Maintenance issue not found");

			// Verify property ownership
			if (issue.Property.OwnerId != CurrentUserId)
				throw new UnauthorizedAccessException("Access denied to this maintenance issue");

			// Verify assigned user exists
			var assignedUser = await Context.Users.FirstOrDefaultAsync(u => u.UserId == assignedToUserId);
			if (assignedUser == null)
				throw new ArgumentException("Assigned user not found");

			issue.AssignedToUserId = assignedToUserId;

			await UnitOfWork.SaveChangesAsync();

			LogInfo("Assigned maintenance issue {IssueId} to user {UserId}", issueId, assignedToUserId);
		}
		catch (Exception ex)
		{
			LogError(ex, "Error assigning maintenance issue {IssueId}", issueId);
			throw;
		}
	}

	/// <summary>
	/// Get maintenance issues assigned to current user
	/// </summary>
	public async Task<List<MaintenanceIssueResponse>> GetAssignedMaintenanceIssuesAsync()
	{
		try
		{
			var assignedIssues = await Context.MaintenanceIssues
					.Where(m => m.AssignedToUserId == CurrentUserId)
					.Include(m => m.Property)
					.Include(m => m.Status)
					.Include(m => m.Priority)
					.OrderByDescending(m => m.CreatedAt)
					.AsNoTracking()
					.ToListAsync();

			return assignedIssues.ToResponseList();
		}
		catch (Exception ex)
		{
			LogError(ex, "Error retrieving assigned maintenance issues");
			throw;
		}
	}

	#endregion

	#region Authorization Helper Methods

	/// <summary>
	/// Check if current user can access the maintenance issue
	/// </summary>
	private async Task<bool> CanAccessIssueAsync(MaintenanceIssue issue)
	{
		// User must own the property or be assigned to the issue
		return issue.Property.OwnerId == CurrentUserId || issue.AssignedToUserId == CurrentUserId;
	}

	/// <summary>
	/// Check if current user can update the maintenance issue
	/// </summary>
	private async Task<bool> CanUpdateIssueAsync(MaintenanceIssue issue)
	{
		// Only property owner can update issues
		return issue.Property.OwnerId == CurrentUserId;
	}

	/// <summary>
	/// Check if current user can delete the maintenance issue
	/// </summary>
	private async Task<bool> CanDeleteIssueAsync(MaintenanceIssue issue)
	{
		// Only property owner can delete issues
		return issue.Property.OwnerId == CurrentUserId;
	}

	/// <summary>
	/// Validate that current user owns the specified property
	/// </summary>
	private async Task ValidatePropertyOwnershipAsync(int propertyId)
	{
		var exists = await Context.Properties
			.AnyAsync(p => p.PropertyId == propertyId && p.OwnerId == CurrentUserId);
		
		if (!exists)
			throw new UnauthorizedAccessException("Property not found or access denied");
	}

	#endregion

	#region Helper Methods

	/// <summary>
	/// Get status ID from status name
	/// </summary>
	private int GetStatusId(string status)
	{
		return status.ToLower() switch
		{
			"pending" => (int)MaintenanceIssueStatusEnum.Pending,
			"inprogress" => (int)MaintenanceIssueStatusEnum.InProgress,
			"completed" => (int)MaintenanceIssueStatusEnum.Completed,
			"cancelled" => (int)MaintenanceIssueStatusEnum.Cancelled,
			_ => (int)MaintenanceIssueStatusEnum.Pending
		};
	}

	/// <summary>
	/// Get priority ID from priority name
	/// </summary>
	private int GetPriorityId(string priority)
	{
		return priority.ToLower() switch
		{
			"low" => (int)MaintenanceIssuePriorityEnum.Low,
			"medium" => (int)MaintenanceIssuePriorityEnum.Medium,
			"high" => (int)MaintenanceIssuePriorityEnum.High,
			"emergency" => (int)MaintenanceIssuePriorityEnum.Emergency,
			_ => (int)MaintenanceIssuePriorityEnum.Medium
		};
	}

	#endregion
}
