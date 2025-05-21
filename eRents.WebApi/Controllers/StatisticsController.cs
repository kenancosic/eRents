using eRents.Application.Service.StatisticsService;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
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

        public StatisticsController(IStatisticsService statisticsService)
        {
            _statisticsService = statisticsService;
        }

        [HttpGet("properties")]
        public async Task<ActionResult<PropertyStatisticsDto>> GetPropertyStatistics()
        {
            var stats = await _statisticsService.GetPropertyStatisticsAsync();
            return Ok(stats);
        }

        [HttpGet("maintenance")]
        public async Task<ActionResult<MaintenanceStatisticsDto>> GetMaintenanceStatistics()
        {
            var stats = await _statisticsService.GetMaintenanceStatisticsAsync();
            return Ok(stats);
        }

        [HttpGet("financial")]
        public async Task<ActionResult<FinancialSummaryDto>> GetFinancialSummary([FromQuery] FinancialStatisticsRequest request)
        {
            var summary = await _statisticsService.GetFinancialSummaryAsync(request);
            return Ok(summary);
        }
    }
} 