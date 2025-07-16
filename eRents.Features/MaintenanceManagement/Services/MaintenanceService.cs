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
public class MaintenanceService : IMaintenanceService
{
	private readonly ERentsContext _context;
	private readonly ICurrentUserService _currentUserService;
	private readonly IUnitOfWork _unitOfWork;
	private readonly ILogger<MaintenanceService> _logger;

	public MaintenanceService(
			ERentsContext context,
			ICurrentUserService currentUserService,
			IUnitOfWork unitOfWork,
			ILogger<MaintenanceService> logger)
	{
		_context = context;
		_currentUserService = currentUserService;
		_unitOfWork = unitOfWork;
		_logger = logger;
	}

	#region Maintenance Issue CRUD

	/// <summary>
	/// Get maintenance issue by ID
	/// </summary>
	public async Task<MaintenanceIssueResponse?> GetMaintenanceIssueByIdAsync(int id)
	{
		try
		{
			var currentUserId = _currentUserService.GetUserIdAsInt();

			var issue = await _context.MaintenanceIssues
					.Where(m => m.MaintenanceIssueId == id)
					.Include(m => m.Property)
					.Include(m => m.Status)
					.Include(m => m.Priority)
					.AsNoTracking()
					.FirstOrDefaultAsync();

			if (issue == null) return null;

			// Verify access rights - user must own the property or be assigned to the issue
			if (issue.Property.OwnerId != currentUserId && issue.AssignedToUserId != currentUserId)
				throw new UnauthorizedAccessException("Access denied to this maintenance issue");

			return issue.ToResponse();
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error retrieving maintenance issue {IssueId}", id);
			throw;
		}
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
			var currentUserId = _currentUserService.GetUserIdAsInt();

			var query = _context.MaintenanceIssues
					.Where(m => m.Property.OwnerId == currentUserId || m.AssignedToUserId == currentUserId);

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
			_logger.LogError(ex, "Error retrieving user maintenance issues");
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
			var currentUserId = _currentUserService.GetUserIdAsInt();

			// Verify property ownership
			var property = await _context.Properties
					.FirstOrDefaultAsync(p => p.PropertyId == propertyId && p.OwnerId == currentUserId);

			if (property == null)
				throw new UnauthorizedAccessException("Property not found or access denied");

			var issues = await _context.MaintenanceIssues
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
			_logger.LogError(ex, "Error retrieving maintenance issues for property {PropertyId}", propertyId);
			throw;
		}
	}

	/// <summary>
	/// Create new maintenance issue
	/// </summary>
	public async Task<MaintenanceIssueResponse> CreateMaintenanceIssueAsync(MaintenanceIssueRequest request)
	{
		try
		{
			var currentUserId = _currentUserService.GetUserIdAsInt();

			// Verify property ownership
			var property = await _context.Properties
					.FirstOrDefaultAsync(p => p.PropertyId == request.PropertyId && p.OwnerId == currentUserId);

			if (property == null)
				throw new UnauthorizedAccessException("Property not found or access denied");

			var issue = request.ToEntity(currentUserId.Value);

			_context.MaintenanceIssues.Add(issue);
			await _unitOfWork.SaveChangesAsync();

			_logger.LogInformation("Created maintenance issue {IssueId} for property {PropertyId}", issue.MaintenanceIssueId, request.PropertyId);

			// Reload with navigation properties for response
			await _context.Entry(issue).Reference(m => m.Status).LoadAsync();
			await _context.Entry(issue).Reference(m => m.Priority).LoadAsync();

			return issue.ToResponse();
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error creating maintenance issue for property {PropertyId}", request.PropertyId);
			throw;
		}
	}

	/// <summary>
	/// Update existing maintenance issue
	/// </summary>
	public async Task<MaintenanceIssueResponse> UpdateMaintenanceIssueAsync(int id, MaintenanceIssueRequest request)
	{
		try
		{
			var currentUserId = _currentUserService.GetUserIdAsInt();

			var issue = await _context.MaintenanceIssues
					.Include(m => m.Property)
					.Include(m => m.Status)
					.Include(m => m.Priority)
					.FirstOrDefaultAsync(m => m.MaintenanceIssueId == id);

			if (issue == null)
				throw new ArgumentException("Maintenance issue not found");

			// Verify access rights
			if (issue.Property.OwnerId != currentUserId)
				throw new UnauthorizedAccessException("Access denied to this maintenance issue");

			issue.UpdateFromRequest(request);

			await _unitOfWork.SaveChangesAsync();

			_logger.LogInformation("Updated maintenance issue {IssueId}", id);

			return issue.ToResponse();
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error updating maintenance issue {IssueId}", id);
			throw;
		}
	}

	/// <summary>
	/// Update maintenance issue status
	/// </summary>
	public async Task UpdateMaintenanceStatusAsync(int id, MaintenanceStatusUpdateRequest request)
	{
		try
		{
			var currentUserId = _currentUserService.GetUserIdAsInt();

			var issue = await _context.MaintenanceIssues
					.Include(m => m.Property)
					.FirstOrDefaultAsync(m => m.MaintenanceIssueId == id);

			if (issue == null)
				throw new ArgumentException("Maintenance issue not found");

			// Verify access rights - owner or assigned user can update status
			if (issue.Property.OwnerId != currentUserId && issue.AssignedToUserId != currentUserId)
				throw new UnauthorizedAccessException("Access denied to this maintenance issue");

			issue.UpdateStatusFromRequest(request);

			await _unitOfWork.SaveChangesAsync();

			_logger.LogInformation("Updated maintenance issue {IssueId} status to {Status}", id, request.Status);
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error updating maintenance issue {IssueId} status", id);
			throw;
		}
	}

	/// <summary>
	/// Delete maintenance issue
	/// </summary>
	public async Task DeleteMaintenanceIssueAsync(int id)
	{
		try
		{
			var currentUserId = _currentUserService.GetUserIdAsInt();

			var issue = await _context.MaintenanceIssues
					.Include(m => m.Property)
					.FirstOrDefaultAsync(m => m.MaintenanceIssueId == id);

			if (issue == null)
				throw new ArgumentException("Maintenance issue not found");

			// Verify property ownership
			if (issue.Property.OwnerId != currentUserId)
				throw new UnauthorizedAccessException("Access denied to this maintenance issue");

			_context.MaintenanceIssues.Remove(issue);
			await _unitOfWork.SaveChangesAsync();

			_logger.LogInformation("Deleted maintenance issue {IssueId}", id);
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error deleting maintenance issue {IssueId}", id);
			throw;
		}
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
			var currentUserId = _currentUserService.GetUserIdAsInt();

			var userPropertyIds = await _context.Properties
					.Where(p => p.OwnerId == currentUserId)
					.Select(p => p.PropertyId)
					.ToListAsync();

			var issues = await _context.MaintenanceIssues
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
			_logger.LogError(ex, "Error retrieving maintenance statistics");
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
			var currentUserId = _currentUserService.GetUserIdAsInt();

			// Verify property ownership
			var property = await _context.Properties
					.FirstOrDefaultAsync(p => p.PropertyId == propertyId && p.OwnerId == currentUserId);

			if (property == null)
				throw new UnauthorizedAccessException("Property not found or access denied");

			var issues = await _context.MaintenanceIssues
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
			_logger.LogError(ex, "Error retrieving maintenance summary for property {PropertyId}", propertyId);
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
			var currentUserId = _currentUserService.GetUserIdAsInt();
			var overdueThreshold = DateTime.UtcNow.AddDays(-7);

			var userPropertyIds = await _context.Properties
					.Where(p => p.OwnerId == currentUserId)
					.Select(p => p.PropertyId)
					.ToListAsync();

			var overdueIssues = await _context.MaintenanceIssues
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
			_logger.LogError(ex, "Error retrieving overdue maintenance issues");
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
			var currentUserId = _currentUserService.GetUserIdAsInt();
			var recentThreshold = DateTime.UtcNow.AddDays(-days);

			var userPropertyIds = await _context.Properties
					.Where(p => p.OwnerId == currentUserId)
					.Select(p => p.PropertyId)
					.ToListAsync();

			var recentIssues = await _context.MaintenanceIssues
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
			_logger.LogError(ex, "Error retrieving recent maintenance issues");
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
			var currentUserId = _currentUserService.GetUserIdAsInt();

			var issue = await _context.MaintenanceIssues
					.Include(m => m.Property)
					.FirstOrDefaultAsync(m => m.MaintenanceIssueId == issueId);

			if (issue == null)
				throw new ArgumentException("Maintenance issue not found");

			// Verify property ownership
			if (issue.Property.OwnerId != currentUserId)
				throw new UnauthorizedAccessException("Access denied to this maintenance issue");

			// Verify assigned user exists
			var assignedUser = await _context.Users.FirstOrDefaultAsync(u => u.UserId == assignedToUserId);
			if (assignedUser == null)
				throw new ArgumentException("Assigned user not found");

			issue.AssignedToUserId = assignedToUserId;

			await _unitOfWork.SaveChangesAsync();

			_logger.LogInformation("Assigned maintenance issue {IssueId} to user {UserId}", issueId, assignedToUserId);
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error assigning maintenance issue {IssueId}", issueId);
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
			var currentUserId = _currentUserService.GetUserIdAsInt();

			var assignedIssues = await _context.MaintenanceIssues
					.Where(m => m.AssignedToUserId == currentUserId)
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
			_logger.LogError(ex, "Error retrieving assigned maintenance issues");
			throw;
		}
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
