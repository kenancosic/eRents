using eRents.Features.FinancialManagement.DTOs;
using eRents.Features.FinancialManagement.Services;
using eRents.Features.Shared.Controllers;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;

namespace eRents.Features.FinancialManagement.Controllers;

/// <summary>
/// StatisticsController for the FinancialManagement feature
/// Handles financial metrics and dashboard statistics
/// </summary>
[ApiController]
[Route("api/financial/statistics")]
[Authorize]
public class StatisticsController : BaseController
{
    private readonly IStatisticsService _statisticsService;
    private readonly ILogger<StatisticsController> _logger;

    public StatisticsController(
        IStatisticsService statisticsService,
        ILogger<StatisticsController> logger)
    {
        _statisticsService = statisticsService;
        _logger = logger;
    }

    /// <summary>
    /// Get basic financial metrics for current user
    /// </summary>
    [HttpGet("dashboard")]
    public async Task<ActionResult<FinancialSummaryResponse>> GetDashboardStatistics()
    {
        try
        {
            var stats = await _statisticsService.GetBasicFinancialStatsAsync();
            return Ok(stats);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving dashboard statistics");
            return BadRequest(new { message = "Failed to retrieve dashboard statistics" });
        }
    }

    /// <summary>
    /// Get monthly revenue data for the current year
    /// </summary>
    [HttpGet("monthly-revenue")]
    public async Task<ActionResult<IEnumerable<MonthlyRevenueResponse>>> GetCurrentYearRevenue()
    {
        try
        {
            var revenue = await _statisticsService.GetCurrentYearRevenueAsync();
            return Ok(revenue);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving current year revenue");
            return BadRequest(new { message = "Failed to retrieve current year revenue" });
        }
    }

    /// <summary>
    /// Get total revenue for specific property
    /// </summary>
    [HttpGet("property/{propertyId}/revenue")]
    public async Task<ActionResult<object>> GetPropertyTotalRevenue(int propertyId)
    {
        try
        {
            var totalRevenue = await _statisticsService.GetPropertyTotalRevenueAsync(propertyId);
            return Ok(new { 
                PropertyId = propertyId,
                TotalRevenue = totalRevenue 
            });
        }
        catch (UnauthorizedAccessException)
        {
            return Forbid();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving total revenue for property {PropertyId}", propertyId);
            return BadRequest(new { message = "Failed to retrieve property revenue" });
        }
    }

    /// <summary>
    /// Get maintenance costs for specific property
    /// </summary>
    [HttpGet("property/{propertyId}/maintenance-costs")]
    public async Task<ActionResult<object>> GetPropertyMaintenanceCosts(
        int propertyId,
        [FromQuery] DateTime? startDate = null,
        [FromQuery] DateTime? endDate = null)
    {
        try
        {
            var maintenanceCosts = await _statisticsService.GetPropertyMaintenanceCostsAsync(propertyId, startDate, endDate);
            return Ok(new 
            { 
                PropertyId = propertyId,
                MaintenanceCosts = maintenanceCosts,
                StartDate = startDate?.ToString("yyyy-MM-dd"),
                EndDate = endDate?.ToString("yyyy-MM-dd")
            });
        }
        catch (UnauthorizedAccessException)
        {
            return Forbid();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving maintenance costs for property {PropertyId}", propertyId);
            return BadRequest(new { message = "Failed to retrieve maintenance costs" });
        }
    }

    /// <summary>
    /// Get occupancy rate for property
    /// </summary>
    [HttpGet("property/{propertyId}/occupancy")]
    public async Task<ActionResult<object>> GetPropertyOccupancyRate(
        int propertyId,
        [FromQuery] DateTime? startDate = null,
        [FromQuery] DateTime? endDate = null)
    {
        try
        {
            var occupancyRate = await _statisticsService.GetPropertyOccupancyRateAsync(propertyId, startDate, endDate);
            return Ok(new 
            { 
                PropertyId = propertyId,
                OccupancyRate = Math.Round(occupancyRate, 2),
                StartDate = startDate?.ToString("yyyy-MM-dd") ?? new DateTime(DateTime.UtcNow.Year, 1, 1).ToString("yyyy-MM-dd"),
                EndDate = endDate?.ToString("yyyy-MM-dd") ?? DateTime.UtcNow.ToString("yyyy-MM-dd")
            });
        }
        catch (UnauthorizedAccessException)
        {
            return Forbid();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving occupancy rate for property {PropertyId}", propertyId);
            return BadRequest(new { message = "Failed to retrieve occupancy rate" });
        }
    }

    /// <summary>
    /// Get comprehensive property statistics
    /// </summary>
    [HttpGet("property/{propertyId}/overview")]
    public async Task<ActionResult<object>> GetPropertyStatisticsOverview(
        int propertyId,
        [FromQuery] DateTime? startDate = null,
        [FromQuery] DateTime? endDate = null)
    {
        try
        {
            // Get all statistics for the property
            var totalRevenue = await _statisticsService.GetPropertyTotalRevenueAsync(propertyId);
            var maintenanceCosts = await _statisticsService.GetPropertyMaintenanceCostsAsync(propertyId, startDate, endDate);
            var occupancyRate = await _statisticsService.GetPropertyOccupancyRateAsync(propertyId, startDate, endDate);

            return Ok(new 
            { 
                PropertyId = propertyId,
                TotalRevenue = totalRevenue,
                MaintenanceCosts = maintenanceCosts,
                NetIncome = totalRevenue - maintenanceCosts,
                OccupancyRate = Math.Round(occupancyRate, 2),
                StartDate = startDate?.ToString("yyyy-MM-dd"),
                EndDate = endDate?.ToString("yyyy-MM-dd")
            });
        }
        catch (UnauthorizedAccessException)
        {
            return Forbid();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving property statistics overview for {PropertyId}", propertyId);
            return BadRequest(new { message = "Failed to retrieve property statistics" });
        }
    }

    /// <summary>
    /// Get quick financial metrics for multiple properties
    /// </summary>
    [HttpGet("quick-metrics")]
    public async Task<ActionResult<object>> GetQuickMetrics()
    {
        try
        {
            var stats = await _statisticsService.GetBasicFinancialStatsAsync();
            
            return Ok(new 
            { 
                TotalIncome = stats.TotalRentIncome,
                TotalExpenses = stats.TotalMaintenanceCosts,
                NetProfit = stats.NetTotal,
                MonthlyAverage = Math.Round(stats.AverageMonthlyIncome, 2),
                PropertiesCount = stats.TotalProperties,
                ActiveBookings = stats.ActiveBookings,
                Year = DateTime.UtcNow.Year
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving quick metrics");
            return BadRequest(new { message = "Failed to retrieve quick metrics" });
        }
    }

    /// <summary>
    /// Get year-over-year comparison (placeholder for future enhancement)
    /// </summary>
    [HttpGet("year-comparison")]
    public async Task<ActionResult<object>> GetYearOverYearComparison(
        [FromQuery] int? previousYear = null)
    {
        try
        {
            var currentYear = DateTime.UtcNow.Year;
            var compareYear = previousYear ?? currentYear - 1;

            // Get current year stats
            var currentStats = await _statisticsService.GetBasicFinancialStatsAsync();

            // For now, return current year data with placeholder for comparison
            // Future enhancement: implement actual year-over-year comparison
            return Ok(new 
            { 
                CurrentYear = new 
                {
                    Year = currentYear,
                    TotalIncome = currentStats.TotalRentIncome,
                    TotalExpenses = currentStats.TotalMaintenanceCosts,
                    NetProfit = currentStats.NetTotal
                },
                ComparisonYear = new 
                {
                    Year = compareYear,
                    Message = "Year-over-year comparison coming soon"
                },
                GrowthPercentage = 0 // Placeholder
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving year-over-year comparison");
            return BadRequest(new { message = "Failed to retrieve year comparison" });
        }
    }
}
