using eRents.Application.Service.StatisticsService;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Shared.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Threading.Tasks;

namespace eRents.WebApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize(Roles = "Landlord")]
    public class StatisticsController : ControllerBase
    {
        private readonly IStatisticsService _statisticsService;
        private readonly ICurrentUserService _currentUserService;

        public StatisticsController(IStatisticsService statisticsService, ICurrentUserService currentUserService)
        {
            _statisticsService = statisticsService;
            _currentUserService = currentUserService;
        }

        [HttpGet("dashboard")]
        public async Task<ActionResult<DashboardStatisticsDto>> GetDashboardStatistics()
        {
            var userId = _currentUserService.UserId;
            if (userId == null)
                return Unauthorized();

            var dashboard = await _statisticsService.GetDashboardStatisticsAsync(userId);
            return Ok(dashboard);
        }

        [HttpGet("properties")]
        public async Task<ActionResult<PropertyStatisticsDto>> GetPropertyStatistics()
        {
            var userId = _currentUserService.UserId;
            if (userId == null)
                return Unauthorized();

            var stats = await _statisticsService.GetPropertyStatisticsAsync(userId);
            return Ok(stats);
        }

        [HttpGet("maintenance")]
        public async Task<ActionResult<MaintenanceStatisticsDto>> GetMaintenanceStatistics()
        {
            var userId = _currentUserService.UserId;
            if (userId == null)
                return Unauthorized();

            var stats = await _statisticsService.GetMaintenanceStatisticsAsync(userId);
            return Ok(stats);
        }

        [HttpGet("financial")]
        public async Task<ActionResult<FinancialSummaryDto>> GetFinancialSummary([FromQuery] FinancialStatisticsRequest request)
        {
            var userId = _currentUserService.UserId;
            if (userId == null)
                return Unauthorized();

            var summary = await _statisticsService.GetFinancialSummaryAsync(userId, request);
            return Ok(summary);
        }
    }
} 