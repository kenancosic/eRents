using eRents.Application.Services.ReportService;
using eRents.Application.Services.UserService;
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
    public class ReportsController : ControllerBase
    {
        private readonly IReportService _reportService;

        private readonly ILogger<ReportsController> _logger;
        private readonly ICurrentUserService _currentUserService;

        public ReportsController(
            IReportService reportService,
            ILogger<ReportsController> logger,
            ICurrentUserService currentUserService)
        {
            _reportService = reportService;
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
        /// Get financial report for desktop users
        /// </summary>
        [HttpGet("financial")]
        public async Task<IActionResult> GetFinancialReport([FromQuery] DateTime startDate, [FromQuery] DateTime endDate)
        {
            try
            {
                // Platform validation - reports only available on desktop
                if (!ValidatePlatform("desktop", out var platformError))
                    return platformError!;

                var userIdString = _currentUserService.UserId;
                if (string.IsNullOrEmpty(userIdString) || !int.TryParse(userIdString, out int userId))
                {
                    _logger.LogWarning("Financial report request failed - Invalid user ID for user {UserId}", userIdString);
                    return Unauthorized("Invalid user ID in token");
                }

                var report = await _reportService.GetFinancialReportAsync(userId, startDate, endDate);
                
                _logger.LogInformation("User {UserId} retrieved financial report for period {StartDate} to {EndDate} on desktop platform", 
                    userId, startDate, endDate);
                
                return Ok(report);
            }
            catch (Exception ex)
            {
                return HandleStandardError(ex, $"Financial report retrieval (Period: {startDate} to {endDate})");
            }
        }

        /// <summary>
        /// Get tenant report for desktop users
        /// </summary>
        [HttpGet("tenant")]
        public async Task<IActionResult> GetTenantReport([FromQuery] DateTime startDate, [FromQuery] DateTime endDate)
        {
            try
            {
                // Platform validation - reports only available on desktop
                if (!ValidatePlatform("desktop", out var platformError))
                    return platformError!;

                var userIdString = _currentUserService.UserId;
                if (string.IsNullOrEmpty(userIdString) || !int.TryParse(userIdString, out int userId))
                {
                    _logger.LogWarning("Tenant report request failed - Invalid user ID for user {UserId}", userIdString);
                    return Unauthorized("Invalid user ID in token");
                }

                var report = await _reportService.GetTenantReportAsync(userId, startDate, endDate);
                
                _logger.LogInformation("User {UserId} retrieved tenant report for period {StartDate} to {EndDate} on desktop platform", 
                    userId, startDate, endDate);
                
                return Ok(report);
            }
            catch (Exception ex)
            {
                return HandleStandardError(ex, $"Tenant report retrieval (Period: {startDate} to {endDate})");
            }
        }
    }
} 