using eRents.Features.FinancialManagement.DTOs;
using eRents.Features.FinancialManagement.Services;
using eRents.Features.Shared.Controllers;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;

namespace eRents.Features.FinancialManagement.Controllers;

/// <summary>
/// ReportController for the FinancialManagement feature
/// Handles financial reporting and analysis
/// </summary>
[ApiController]
[Route("api/financial/reports")]
[Authorize]
public class ReportController : BaseController
{
    private readonly IReportService _reportService;
    private readonly ILogger<ReportController> _logger;

    public ReportController(
        IReportService reportService,
        ILogger<ReportController> logger)
    {
        _reportService = reportService;
        _logger = logger;
    }

    /// <summary>
    /// Get financial report for properties within date range
    /// </summary>
    [HttpGet("financial")]
    public async Task<ActionResult<IEnumerable<FinancialReportResponse>>> GetFinancialReport(
        [FromQuery] DateTime startDate,
        [FromQuery] DateTime endDate,
        [FromQuery] int? propertyId = null)
    {
        try
        {
            if (startDate == default || endDate == default)
            {
                return BadRequest(new { message = "Start date and end date are required" });
            }

            if (startDate > endDate)
            {
                return BadRequest(new { message = "Start date cannot be after end date" });
            }

            var report = await _reportService.GetFinancialReportAsync(startDate, endDate, propertyId);
            return Ok(report);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error generating financial report");
            return BadRequest(new { message = "Failed to generate financial report" });
        }
    }

    /// <summary>
    /// Get financial summary for current user's properties
    /// </summary>
    [HttpGet("summary")]
    public async Task<ActionResult<FinancialSummaryResponse>> GetFinancialSummary(
        [FromQuery] DateTime? startDate = null,
        [FromQuery] DateTime? endDate = null,
        [FromQuery] int? propertyId = null)
    {
        try
        {
            // Default to current year if no dates provided
            var defaultStartDate = startDate ?? new DateTime(DateTime.UtcNow.Year, 1, 1);
            var defaultEndDate = endDate ?? DateTime.UtcNow;

            if (defaultStartDate > defaultEndDate)
            {
                return BadRequest(new { message = "Start date cannot be after end date" });
            }

            var summary = await _reportService.GetFinancialSummaryAsync(defaultStartDate, defaultEndDate, propertyId);
            return Ok(summary);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error generating financial summary");
            return BadRequest(new { message = "Failed to generate financial summary" });
        }
    }

    /// <summary>
    /// Get monthly revenue breakdown for the year
    /// </summary>
    [HttpGet("monthly-revenue")]
    public async Task<ActionResult<IEnumerable<MonthlyRevenueResponse>>> GetMonthlyRevenue(
        [FromQuery] int? year = null,
        [FromQuery] int? propertyId = null)
    {
        try
        {
            var targetYear = year ?? DateTime.UtcNow.Year;

            if (targetYear < 2000 || targetYear > DateTime.UtcNow.Year + 1)
            {
                return BadRequest(new { message = "Invalid year provided" });
            }

            var monthlyRevenue = await _reportService.GetMonthlyRevenueAsync(targetYear, propertyId);
            return Ok(monthlyRevenue);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error generating monthly revenue report");
            return BadRequest(new { message = "Failed to generate monthly revenue report" });
        }
    }

    /// <summary>
    /// Get quick financial overview for dashboard
    /// </summary>
    [HttpGet("overview")]
    public async Task<ActionResult<object>> GetFinancialOverview()
    {
        try
        {
            var currentYear = DateTime.UtcNow.Year;
            var startDate = new DateTime(currentYear, 1, 1);
            var endDate = DateTime.UtcNow;

            var summary = await _reportService.GetFinancialSummaryAsync(startDate, endDate);
            
            return Ok(new
            {
                summary.TotalRentIncome,
                summary.TotalMaintenanceCosts,
                summary.NetTotal,
                summary.AverageMonthlyIncome,
                summary.TotalProperties,
                summary.ActiveBookings,
                Year = currentYear
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error generating financial overview");
            return BadRequest(new { message = "Failed to generate financial overview" });
        }
    }

    /// <summary>
    /// Get property-specific financial report
    /// </summary>
    [HttpGet("property/{propertyId}")]
    public async Task<ActionResult<FinancialReportResponse>> GetPropertyFinancialReport(
        int propertyId,
        [FromQuery] DateTime? startDate = null,
        [FromQuery] DateTime? endDate = null)
    {
        try
        {
            // Default to current year if no dates provided
            var defaultStartDate = startDate ?? new DateTime(DateTime.UtcNow.Year, 1, 1);
            var defaultEndDate = endDate ?? DateTime.UtcNow;

            if (defaultStartDate > defaultEndDate)
            {
                return BadRequest(new { message = "Start date cannot be after end date" });
            }

            var reports = await _reportService.GetFinancialReportAsync(defaultStartDate, defaultEndDate, propertyId);
            var propertyReport = reports.FirstOrDefault();

            if (propertyReport == null)
            {
                return NotFound(new { message = "No financial data found for this property in the specified period" });
            }

            return Ok(propertyReport);
        }
        catch (UnauthorizedAccessException)
        {
            return Forbid();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error generating property financial report for {PropertyId}", propertyId);
            return BadRequest(new { message = "Failed to generate property financial report" });
        }
    }

    /// <summary>
    /// Export financial report as CSV (placeholder for future enhancement)
    /// </summary>
    [HttpGet("export")]
    public async Task<IActionResult> ExportFinancialReport(
        [FromQuery] DateTime startDate,
        [FromQuery] DateTime endDate,
        [FromQuery] string format = "csv")
    {
        try
        {
            if (startDate == default || endDate == default)
            {
                return BadRequest(new { message = "Start date and end date are required" });
            }

            // For now, return the data as JSON
            // Future enhancement: implement actual CSV export
            var report = await _reportService.GetFinancialReportAsync(startDate, endDate);
            
            return Ok(new 
            { 
                message = "Export functionality coming soon",
                data = report,
                format = format
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error exporting financial report");
            return BadRequest(new { message = "Failed to export financial report" });
        }
    }
}
