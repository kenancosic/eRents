using eRents.Application.Service.StatisticsService;
using eRents.Application.Service.UserService;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Shared.SearchObjects;
using eRents.Shared.Services;
using eRents.WebApi.Controllers.Base;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace eRents.WebApi.Controllers
{
	[ApiController]
	[Route("[controller]")]
	[Authorize] // Require authentication for all endpoints
	public class StatisticsController : ControllerBase
	{
		private readonly IStatisticsService _statisticsService;

		private readonly ILogger<StatisticsController> _logger;
		private readonly ICurrentUserService _currentUserService;

		public StatisticsController(
			IStatisticsService statisticsService,
			ILogger<StatisticsController> logger,
			ICurrentUserService currentUserService)
		{
			_statisticsService = statisticsService;
			_logger = logger;
			_currentUserService = currentUserService;
		}

		/// <summary>
		/// Validates that the request is coming from the allowed platform (desktop vs mobile)
		/// </summary>
		protected bool ValidatePlatform(string allowedPlatform, out IActionResult? errorResult)
		{
			var clientType = Request.Headers["Client-Type"].FirstOrDefault()?.ToLower();
			
			if (clientType != allowedPlatform.ToLower())
			{
				_logger.LogWarning("Operation attempted from unauthorized platform: {ClientType}, expected: {AllowedPlatform}", 
					clientType, allowedPlatform);
					
				errorResult = BadRequest(new { 
					Type = "Platform",
					Message = $"This operation is only available on {allowedPlatform} platform",
					Timestamp = DateTime.UtcNow,
					TraceId = HttpContext.TraceIdentifier,
					Path = Request.Path.Value
				});
				return false;
			}
			
			errorResult = null;
			return true;
		}

		/// <summary>
		/// Handles all types of exceptions with appropriate HTTP status codes and standardized error responses
		/// </summary>
		protected IActionResult HandleStandardError(Exception ex, string operation)
		{
			var requestId = HttpContext.TraceIdentifier;
			var path = Request.Path.Value;
			var userId = _currentUserService.UserId ?? "unknown";
			
			_logger.LogError(ex, "{Operation} failed - Error for user {UserId} on {Path}", 
				operation, userId, path);
				
			return StatusCode(500, new { 
				Type = "Internal",
				Message = "An unexpected error occurred while processing your request",
				Timestamp = DateTime.UtcNow,
				TraceId = requestId,
				Path = path
			});
		}

		/// <summary>
		/// Get comprehensive dashboard statistics for desktop users
		/// </summary>
		[HttpGet("dashboard")]
		public async Task<IActionResult> GetDashboardStatistics()
		{
			try
			{
				// Platform validation - analytics only available on desktop
				if (!ValidatePlatform("desktop", out var platformError))
					return platformError!;

				var userIdString = _currentUserService.UserId;
				if (string.IsNullOrEmpty(userIdString) || !int.TryParse(userIdString, out int userId))
				{
					_logger.LogWarning("Dashboard statistics request failed - Invalid user ID for user {UserId}", userIdString);
					return Unauthorized("Invalid user ID in token");
				}

				var statistics = await _statisticsService.GetDashboardStatisticsAsync(userId);
				
				_logger.LogInformation("User {UserId} retrieved dashboard statistics on desktop platform", userId);
				
				return Ok(statistics);
			}
			catch (Exception ex)
			{
				return HandleStandardError(ex, "Dashboard statistics retrieval");
			}
		}

		/// <summary>
		/// Get property statistics for desktop users
		/// </summary>
		[HttpGet("properties")]
		public async Task<IActionResult> GetPropertyStatistics()
		{
			try
			{
				// Platform validation - analytics only available on desktop
				if (!ValidatePlatform("desktop", out var platformError))
					return platformError!;

				var userIdString = _currentUserService.UserId;
				if (string.IsNullOrEmpty(userIdString) || !int.TryParse(userIdString, out int userId))
				{
					_logger.LogWarning("Property statistics request failed - Invalid user ID for user {UserId}", userIdString);
					return Unauthorized("Invalid user ID in token");
				}

				var statistics = await _statisticsService.GetPropertyStatisticsAsync(userId);
				
				_logger.LogInformation("User {UserId} retrieved property statistics on desktop platform", userId);
				
				return Ok(statistics);
			}
			catch (Exception ex)
			{
				return HandleStandardError(ex, "Property statistics retrieval");
			}
		}

		/// <summary>
		/// Get maintenance statistics for desktop users
		/// </summary>
		[HttpGet("maintenance")]
		public async Task<IActionResult> GetMaintenanceStatistics()
		{
			try
			{
				// Platform validation - analytics only available on desktop
				if (!ValidatePlatform("desktop", out var platformError))
					return platformError!;

				var userIdString = _currentUserService.UserId;
				if (string.IsNullOrEmpty(userIdString) || !int.TryParse(userIdString, out int userId))
				{
					_logger.LogWarning("Maintenance statistics request failed - Invalid user ID for user {UserId}", userIdString);
					return Unauthorized("Invalid user ID in token");
				}

				var statistics = await _statisticsService.GetMaintenanceStatisticsAsync(userId);
				
				_logger.LogInformation("User {UserId} retrieved maintenance statistics on desktop platform", userId);
				
				return Ok(statistics);
			}
			catch (Exception ex)
			{
				return HandleStandardError(ex, "Maintenance statistics retrieval");
			}
		}

		/// <summary>
		/// Get financial summary for desktop users
		/// </summary>
		[HttpPost("financial")]
		public async Task<IActionResult> GetFinancialSummary([FromBody] FinancialStatisticsRequest request)
		{
			try
			{
				// Platform validation - financial analytics only available on desktop
				if (!ValidatePlatform("desktop", out var platformError))
					return platformError!;

				var userIdString = _currentUserService.UserId;
				if (string.IsNullOrEmpty(userIdString) || !int.TryParse(userIdString, out int userId))
				{
					_logger.LogWarning("Financial summary request failed - Invalid user ID for user {UserId}", userIdString);
					return Unauthorized("Invalid user ID in token");
				}

				var statistics = await _statisticsService.GetFinancialSummaryAsync(userId, request);
				
				_logger.LogInformation("User {UserId} retrieved financial summary for period {StartDate} to {EndDate} on desktop platform", 
					userId, request.StartDate, request.EndDate);
				
				return Ok(statistics);
			}
			catch (Exception ex)
			{
				return HandleStandardError(ex, $"Financial summary retrieval (Period: {request?.StartDate} to {request?.EndDate})");
			}
		}
	}
} 