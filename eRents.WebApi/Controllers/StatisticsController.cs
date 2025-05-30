using eRents.Application.Service.StatisticsService;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace eRents.WebApi.Controllers
{
	[ApiController]
	[Route("api/[controller]")]
	[Authorize] // Require authentication for all endpoints
	public class StatisticsController : ControllerBase
	{
		private readonly IStatisticsService _statisticsService;

		public StatisticsController(IStatisticsService statisticsService)
		{
			_statisticsService = statisticsService;
		}

		/// <summary>
		/// Get comprehensive dashboard statistics for desktop users
		/// </summary>
		[HttpGet("dashboard")]
		public async Task<ActionResult<DashboardStatisticsDto>> GetDashboardStatistics()
		{
			try
			{
				// Check platform context from JWT - only desktop users get analytics
				var clientType = User.FindFirst("ClientType")?.Value?.ToLower();
				if (clientType != "desktop")
				{
					return BadRequest("Analytics are only available on desktop platform");
				}

				var userIdClaim = User.FindFirst("UserId")?.Value;
				if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
				{
					return Unauthorized("Invalid user ID in token");
				}

				var statistics = await _statisticsService.GetDashboardStatisticsAsync(userId);
				return Ok(statistics);
			}
			catch (Exception ex)
			{
				return BadRequest($"Error retrieving dashboard statistics: {ex.Message}");
			}
		}

		/// <summary>
		/// Get property statistics for desktop users
		/// </summary>
		[HttpGet("properties")]
		public async Task<ActionResult<PropertyStatisticsDto>> GetPropertyStatistics()
		{
			try
			{
				// Check platform context from JWT - only desktop users get analytics
				var clientType = User.FindFirst("ClientType")?.Value?.ToLower();
				if (clientType != "desktop")
				{
					return BadRequest("Analytics are only available on desktop platform");
				}

				var userIdClaim = User.FindFirst("UserId")?.Value;
				if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
				{
					return Unauthorized("Invalid user ID in token");
				}

				var statistics = await _statisticsService.GetPropertyStatisticsAsync(userId);
				return Ok(statistics);
			}
			catch (Exception ex)
			{
				return BadRequest($"Error retrieving property statistics: {ex.Message}");
			}
		}

		/// <summary>
		/// Get maintenance statistics for desktop users
		/// </summary>
		[HttpGet("maintenance")]
		public async Task<ActionResult<MaintenanceStatisticsDto>> GetMaintenanceStatistics()
		{
			try
			{
				// Check platform context from JWT - only desktop users get analytics
				var clientType = User.FindFirst("ClientType")?.Value?.ToLower();
				if (clientType != "desktop")
				{
					return BadRequest("Analytics are only available on desktop platform");
				}

				var userIdClaim = User.FindFirst("UserId")?.Value;
				if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
				{
					return Unauthorized("Invalid user ID in token");
				}

				var statistics = await _statisticsService.GetMaintenanceStatisticsAsync(userId);
				return Ok(statistics);
			}
			catch (Exception ex)
			{
				return BadRequest($"Error retrieving maintenance statistics: {ex.Message}");
			}
		}

		/// <summary>
		/// Get financial summary for desktop users
		/// </summary>
		[HttpPost("financial")]
		public async Task<ActionResult<FinancialSummaryDto>> GetFinancialSummary([FromBody] FinancialStatisticsRequest request)
		{
			try
			{
				// Check platform context from JWT - only desktop users get analytics
				var clientType = User.FindFirst("ClientType")?.Value?.ToLower();
				if (clientType != "desktop")
				{
					return BadRequest("Financial analytics are only available on desktop platform");
				}

				var userIdClaim = User.FindFirst("UserId")?.Value;
				if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
				{
					return Unauthorized("Invalid user ID in token");
				}

				var statistics = await _statisticsService.GetFinancialSummaryAsync(userId, request);
				return Ok(statistics);
			}
			catch (Exception ex)
			{
				return BadRequest($"Error retrieving financial summary: {ex.Message}");
			}
		}
	}
} 