using eRents.Domain.Models;
using eRents.Features.Core.Controllers;
using eRents.Features.MaintenanceManagement.Models;
using eRents.Features.MaintenanceManagement.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;

namespace eRents.Features.MaintenanceManagement.Controllers
{
    [Authorize]
    [ApiController]
    [Route("api/[controller]")]
    public class MaintenanceIssuesController : CrudController<MaintenanceIssue, MaintenanceIssueRequest, MaintenanceIssueResponse, MaintenanceIssueSearch>
    {
        public MaintenanceIssuesController(MaintenanceIssueService service, ILogger<CrudController<MaintenanceIssue, MaintenanceIssueRequest, MaintenanceIssueResponse, MaintenanceIssueSearch>> logger)
            : base(service, logger)
        {
        }

        /// <summary>
        /// Convenience endpoint to get count of urgent issues (High/Emergency and Pending/InProgress)
        /// </summary>
        [HttpGet("urgent/count")]
        [ProducesResponseType(200, Type = typeof(object))]
        public async Task<ActionResult<object>> GetUrgentCount()
        {
            var search = new MaintenanceIssueSearch
            {
                Page = 1,
                PageSize = 1,
                PriorityMin = Domain.Models.Enums.MaintenanceIssuePriorityEnum.High,
                Statuses = new[]
                {
                    Domain.Models.Enums.MaintenanceIssueStatusEnum.Pending,
                    Domain.Models.Enums.MaintenanceIssueStatusEnum.InProgress
                }
            };

            var result = await _service.GetPagedAsync(search);
            return Ok(new { count = result.TotalCount });
        }
    }
}
