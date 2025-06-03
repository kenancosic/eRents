using eRents.Application.Service.ReportService;
using eRents.Shared.DTO.Response;
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

        public ReportsController(IReportService reportService)
        {
            _reportService = reportService;
        }

        /// <summary>
        /// Get financial report for desktop users
        /// </summary>
        [HttpGet("financial")]
        public async Task<ActionResult<List<FinancialReportResponse>>> GetFinancialReport([FromQuery] DateTime startDate, [FromQuery] DateTime endDate)
        {
            try
            {
                // Check platform context from JWT - only desktop users get reports
                var clientType = User.FindFirst("ClientType")?.Value?.ToLower();
                if (clientType != "desktop")
                {
                    return BadRequest("Reports are only available on desktop platform");
                }

                var userIdClaim = User.FindFirst("UserId")?.Value;
                if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
                {
                    return Unauthorized("Invalid user ID in token");
                }

                var report = await _reportService.GetFinancialReportAsync(userId, startDate, endDate);
                return Ok(report);
            }
            catch (Exception ex)
            {
                return BadRequest($"Error retrieving financial report: {ex.Message}");
            }
        }

        /// <summary>
        /// Get tenant report for desktop users
        /// </summary>
        [HttpGet("tenant")]
        public async Task<ActionResult<List<TenantReportResponse>>> GetTenantReport([FromQuery] DateTime startDate, [FromQuery] DateTime endDate)
        {
            try
            {
                // Check platform context from JWT - only desktop users get reports
                var clientType = User.FindFirst("ClientType")?.Value?.ToLower();
                if (clientType != "desktop")
                {
                    return BadRequest("Reports are only available on desktop platform");
                }

                var userIdClaim = User.FindFirst("UserId")?.Value;
                if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
                {
                    return Unauthorized("Invalid user ID in token");
                }

                var report = await _reportService.GetTenantReportAsync(userId, startDate, endDate);
                return Ok(report);
            }
            catch (Exception ex)
            {
                return BadRequest($"Error retrieving tenant report: {ex.Message}");
            }
        }
    }
} 