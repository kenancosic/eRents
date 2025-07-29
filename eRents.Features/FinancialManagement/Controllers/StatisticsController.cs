using eRents.Features.FinancialManagement.DTOs;
using eRents.Features.FinancialManagement.Services;
using eRents.Features.Shared.Controllers;
using eRents.Features.Shared.Extensions;
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
    /// Get comprehensive dashboard statistics for current user
    /// Includes property, financial, and maintenance summaries
    /// </summary>
    [HttpGet("comprehensive-dashboard")]
    public async Task<ActionResult<DashboardStatisticsResponse>> GetComprehensiveDashboard()
    {
        return await this.ExecuteAsync(
            () => _statisticsService.GetDashboardStatisticsAsync(),
            _logger, "GetComprehensiveDashboard");
    }

    /// <summary>
    /// Get basic financial metrics for current user
    /// </summary>
    [HttpGet("dashboard")]
    public async Task<ActionResult<FinancialSummaryResponse>> GetDashboardStatistics()
    {
        return await this.ExecuteAsync(
            () => _statisticsService.GetBasicFinancialStatsAsync(),
            _logger, "GetDashboardStatistics");
    }

    /// <summary>
    /// Get monthly revenue data for the current year
    /// </summary>
    [HttpGet("monthly-revenue")]
    public async Task<ActionResult<List<MonthlyRevenueResponse>>> GetCurrentYearRevenue()
    {
        return await this.ExecuteAsync(
            () => _statisticsService.GetCurrentYearRevenueAsync(),
            _logger, "GetCurrentYearRevenue");
    }

    /// <summary>
    /// Get total revenue for specific property
    /// </summary>
    [HttpGet("property/{propertyId}/revenue")]
    public async Task<ActionResult<object>> GetPropertyTotalRevenue(int propertyId)
    {
        return await this.ExecuteAsync(async () => {
            var totalRevenue = await _statisticsService.GetPropertyTotalRevenueAsync(propertyId);
            return new { 
                PropertyId = propertyId,
                TotalRevenue = totalRevenue 
            };
        }, _logger, $"GetPropertyTotalRevenue({propertyId})");
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
        return await this.ExecuteAsync(async () => {
            var stats = await _statisticsService.GetBasicFinancialStatsAsync();
            
            return new 
            { 
                TotalIncome = stats.TotalRentIncome,
                TotalExpenses = stats.TotalMaintenanceCosts,
                NetProfit = stats.NetTotal,
                MonthlyAverage = Math.Round(stats.AverageMonthlyIncome, 2),
                PropertiesCount = stats.TotalProperties,
                ActiveBookings = stats.ActiveBookings,
                Year = DateTime.UtcNow.Year
            };
        }, _logger, "GetQuickMetrics");
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
