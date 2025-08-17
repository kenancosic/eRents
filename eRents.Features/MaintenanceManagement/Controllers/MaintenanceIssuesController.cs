using eRents.Domain.Models;
using eRents.Features.Core;
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

        
    }
}
