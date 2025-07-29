using eRents.Features.MaintenanceManagement.DTOs;
using eRents.Features.MaintenanceManagement.Services;
using eRents.Features.Shared.Controllers;
using eRents.Features.Shared.Extensions;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;

namespace eRents.Features.MaintenanceManagement.Controllers;

/// <summary>
/// MaintenanceController for reactive maintenance issues
/// Handles maintenance issues, requests, and tracking
/// </summary>
[ApiController]
[Route("api/maintenance")]
[Authorize]
public class MaintenanceController : BaseController
{
    private readonly IMaintenanceService _maintenanceService;
    private readonly ILogger<MaintenanceController> _logger;

    public MaintenanceController(
        IMaintenanceService maintenanceService,
        ILogger<MaintenanceController> logger)
    {
        _maintenanceService = maintenanceService;
        _logger = logger;
    }

    #region Maintenance Issue CRUD

    /// <summary>
    /// Get maintenance issues for current user with filtering
    /// </summary>
    [HttpGet]
    public async Task<ActionResult<IEnumerable<MaintenanceIssueResponse>>> GetMaintenanceIssues(
        [FromQuery] int? propertyId = null,
        [FromQuery] string? status = null,
        [FromQuery] string? priority = null,
        [FromQuery] DateTime? startDate = null,
        [FromQuery] DateTime? endDate = null)
    {
        try
        {
            var issues = await _maintenanceService.GetUserMaintenanceIssuesAsync(propertyId, status, priority, startDate, endDate);
            return Ok(issues);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving maintenance issues");
            return BadRequest(new { message = "Failed to retrieve maintenance issues" });
        }
    }

    /// <summary>
    /// Get maintenance issue by ID
    /// </summary>
    [HttpGet("{id}")]
    public async Task<ActionResult<MaintenanceIssueResponse>> GetMaintenanceIssue(int id)
        => await this.GetByIdAsync<MaintenanceIssueResponse, int>(id, _maintenanceService.GetMaintenanceIssueByIdAsync, _logger);

    /// <summary>
    /// Get maintenance issues for specific property
    /// </summary>
    [HttpGet("property/{propertyId}")]
    public async Task<ActionResult<IEnumerable<MaintenanceIssueResponse>>> GetPropertyMaintenanceIssues(int propertyId)
    {
        try
        {
            var issues = await _maintenanceService.GetPropertyMaintenanceIssuesAsync(propertyId);
            return Ok(issues);
        }
        catch (UnauthorizedAccessException)
        {
            return Forbid();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving maintenance issues for property {PropertyId}", propertyId);
            return BadRequest(new { message = "Failed to retrieve property maintenance issues" });
        }
    }

    /// <summary>
    /// Create new maintenance issue
    /// </summary>
    [HttpPost]
    public async Task<ActionResult<MaintenanceIssueResponse>> CreateMaintenanceIssue([FromBody] MaintenanceIssueRequest request)
        => await this.CreateAsync<MaintenanceIssueRequest, MaintenanceIssueResponse>(
            request,
            _maintenanceService.CreateMaintenanceIssueAsync,
            _logger,
            nameof(GetMaintenanceIssue));

    /// <summary>
    /// Update existing maintenance issue
    /// </summary>
    [HttpPut("{id}")]
    public async Task<ActionResult<MaintenanceIssueResponse>> UpdateMaintenanceIssue(int id, [FromBody] MaintenanceIssueRequest request)
        => await this.UpdateAsync<MaintenanceIssueRequest, MaintenanceIssueResponse>(id, request, _maintenanceService.UpdateMaintenanceIssueAsync, _logger);

    /// <summary>
    /// Update maintenance issue status
    /// </summary>
    [HttpPut("{id}/status")]
    public async Task<IActionResult> UpdateMaintenanceStatus(int id, [FromBody] MaintenanceStatusUpdateRequest request)
        => await this.ExecuteAsync(async () =>
        {
            await _maintenanceService.UpdateMaintenanceStatusAsync(id, request);
        }, _logger, "UpdateMaintenanceStatus");

    /// <summary>
    /// Delete maintenance issue
    /// </summary>
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteMaintenanceIssue(int id)
        => await this.DeleteAsync(id, _maintenanceService.DeleteMaintenanceIssueAsync, _logger);

    #endregion

    #region Maintenance Statistics

    /// <summary>
    /// Get maintenance statistics for current user
    /// </summary>
    [HttpGet("statistics")]
    public async Task<ActionResult<MaintenanceStatisticsResponse>> GetMaintenanceStatistics()
        => await this.ExecuteAsync(async () => await _maintenanceService.GetMaintenanceStatisticsAsync(), _logger, "GetMaintenanceStatistics");

    /// <summary>
    /// Get maintenance summary for specific property
    /// </summary>
    [HttpGet("property/{propertyId}/summary")]
    public async Task<ActionResult<PropertyMaintenanceSummaryResponse>> GetPropertyMaintenanceSummary(int propertyId)
    {
        try
        {
            var summary = await _maintenanceService.GetPropertyMaintenanceSummaryAsync(propertyId);
            return Ok(summary);
        }
        catch (UnauthorizedAccessException)
        {
            return Forbid();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving maintenance summary for property {PropertyId}", propertyId);
            return BadRequest(new { message = "Failed to retrieve property maintenance summary" });
        }
    }

    /// <summary>
    /// Get overdue maintenance issues
    /// </summary>
    [HttpGet("overdue")]
    public async Task<ActionResult<List<MaintenanceIssueResponse>>> GetOverdueMaintenanceIssues()
        => await this.ExecuteAsync(async () => await _maintenanceService.GetOverdueMaintenanceIssuesAsync(), _logger, "GetOverdueMaintenanceIssues");

    /// <summary>
    /// Get recent maintenance issues
    /// </summary>
    [HttpGet("recent")]
    public async Task<ActionResult<IEnumerable<MaintenanceIssueResponse>>> GetRecentMaintenance([FromQuery] int days = 7)
    {
        try
        {
            var recentIssues = await _maintenanceService.GetUpcomingMaintenanceAsync(days);
            return Ok(recentIssues);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving recent maintenance");
            return BadRequest(new { message = "Failed to retrieve recent maintenance" });
        }
    }

    #endregion

    #region Maintenance Assignment

    /// <summary>
    /// Assign maintenance issue to user
    /// </summary>
    [HttpPost("{issueId}/assign")]
    public async Task<IActionResult> AssignMaintenanceIssue(int issueId, [FromBody] AssignMaintenanceRequest request)
    {
        try
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            await _maintenanceService.AssignMaintenanceIssueAsync(issueId, request.AssignedToUserId);
            return Ok(new { message = "Maintenance issue assigned successfully" });
        }
        catch (UnauthorizedAccessException)
        {
            return Forbid();
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error assigning maintenance issue {IssueId}", issueId);
            return BadRequest(new { message = "Failed to assign maintenance issue" });
        }
    }

    /// <summary>
    /// Get maintenance issues assigned to current user
    /// </summary>
    [HttpGet("assigned")]
    public async Task<ActionResult<IEnumerable<MaintenanceIssueResponse>>> GetAssignedMaintenanceIssues()
    {
        try
        {
            var assignedIssues = await _maintenanceService.GetAssignedMaintenanceIssuesAsync();
            return Ok(assignedIssues);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving assigned maintenance issues");
            return BadRequest(new { message = "Failed to retrieve assigned maintenance issues" });
        }
    }

    #endregion

    #region Dashboard and Quick Actions

    /// <summary>
    /// Get maintenance dashboard overview
    /// </summary>
    [HttpGet("dashboard")]
    public async Task<ActionResult<object>> GetMaintenanceDashboard()
    {
        try
        {
            var statistics = await _maintenanceService.GetMaintenanceStatisticsAsync();
            var overdueIssues = await _maintenanceService.GetOverdueMaintenanceIssuesAsync();
            var recentIssues = await _maintenanceService.GetUpcomingMaintenanceAsync(7);

            return Ok(new
            {
                Statistics = statistics,
                OverdueCount = overdueIssues.Count,
                RecentCount = recentIssues.Count,
                RecentOverdue = overdueIssues.Take(5),
                RecentIssues = recentIssues.Take(5)
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving maintenance dashboard");
            return BadRequest(new { message = "Failed to retrieve maintenance dashboard" });
        }
    }

    /// <summary>
    /// Mark multiple issues as completed
    /// </summary>
    [HttpPost("bulk-complete")]
    public async Task<IActionResult> BulkCompleteIssues([FromBody] BulkCompleteRequest request)
    {
        try
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var completedCount = 0;
            var failedIds = new List<int>();

            foreach (var issueId in request.IssueIds)
            {
                try
                {
                    var statusUpdate = new MaintenanceStatusUpdateRequest
                    {
                        Status = "Completed",
                        ResolvedAt = DateTime.UtcNow,
                        ResolutionNotes = request.ResolutionNotes
                    };

                    await _maintenanceService.UpdateMaintenanceStatusAsync(issueId, statusUpdate);
                    completedCount++;
                }
                catch
                {
                    failedIds.Add(issueId);
                }
            }

            return Ok(new 
            { 
                message = $"Completed {completedCount} issues", 
                completedCount,
                failedIds
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error bulk completing maintenance issues");
            return BadRequest(new { message = "Failed to bulk complete maintenance issues" });
        }
    }

    #endregion
}
