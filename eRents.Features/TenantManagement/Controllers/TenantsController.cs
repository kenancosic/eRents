using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using eRents.Features.TenantManagement.Models;
using eRents.Features.Core;

namespace eRents.Features.TenantManagement.Controllers;

[Route("api/[controller]")]
[ApiController]
public class TenantsController : CrudController<eRents.Domain.Models.Tenant, TenantRequest, TenantResponse, TenantSearch>
{
    public TenantsController(
        ICrudService<eRents.Domain.Models.Tenant, TenantRequest, TenantResponse, TenantSearch> service,
        ILogger<TenantsController> logger)
        : base(service, logger)
    {
    }
}