using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using eRents.Features.PropertyManagement.Models;
using eRents.Domain.Models;
using eRents.Features.Core;
using System.Threading.Tasks;
using eRents.Features.PropertyManagement.Services;

namespace eRents.Features.PropertyManagement.Controllers;

[Route("api/[controller]")]
[ApiController]
public class PropertiesController : CrudController<Property, PropertyRequest, PropertyResponse, PropertySearch>
{
    private readonly PropertyService _propertyService;

    public PropertiesController(
            ICrudService<Property, PropertyRequest, PropertyResponse, PropertySearch> service,
            ILogger<PropertiesController> logger)
            : base(service, logger)
    {
        _propertyService = service as PropertyService ?? throw new System.InvalidOperationException("PropertyService not registered correctly");
    }

    [HttpGet("{id}/current-tenant")]
    public async Task<ActionResult<PropertyTenantSummary>> GetCurrentTenant(int id)
    {
        var summary = await _propertyService.GetCurrentTenantSummaryAsync(id);
        if (summary == null)
            return NoContent();
        return Ok(summary);
    }
}