using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using eRents.Features.TenantManagement.Models;
using eRents.Features.Core;
using eRents.Features.TenantManagement.Services;

namespace eRents.Features.TenantManagement.Controllers;

[Route("api/[controller]")]
[ApiController]
public class TenantsController : CrudController<eRents.Domain.Models.Tenant, TenantRequest, TenantResponse, TenantSearch>
{
    private readonly TenantService _tenantService;
    private readonly ILogger<TenantsController> _logger;

    public TenantsController(
        ICrudService<eRents.Domain.Models.Tenant, TenantRequest, TenantResponse, TenantSearch> service,
        ILogger<TenantsController> logger,
        TenantService tenantService)
        : base(service, logger)
    {
        _tenantService = tenantService;
        _logger = logger;
    }

    [HttpPost("{id}/accept-and-reject-others")]
    [ProducesResponseType(200, Type = typeof(TenantResponse))]
    [ProducesResponseType(404)]
    [ProducesResponseType(500)]
    public async Task<ActionResult<TenantResponse>> AcceptTenantAndRejectOthers(int id)
    {
        try
        {
            var result = await _tenantService.AcceptTenantAndRejectOthersAsync(id);
            return Ok(result);
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error accepting Tenant with ID {Id} and rejecting others", id);
            return StatusCode(500, "An error occurred while processing your request.");
        }
    }

    [HttpPost("{id}/reject")]
    [ProducesResponseType(200, Type = typeof(TenantResponse))]
    [ProducesResponseType(404)]
    [ProducesResponseType(500)]
    public async Task<ActionResult<TenantResponse>> Reject(int id)
    {
        try
        {
            var result = await _tenantService.RejectTenantRequestAsync(id);
            return Ok(result);
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error rejecting Tenant with ID {Id}", id);
            return StatusCode(500, "An error occurred while processing your request.");
        }
    }

    [HttpPost("{id}/cancel")]
    [ProducesResponseType(200, Type = typeof(TenantResponse))]
    [ProducesResponseType(404)]
    [ProducesResponseType(500)]
    public async Task<ActionResult<TenantResponse>> Cancel(int id, [FromQuery] DateOnly? cancelDate)
    {
        try
        {
            var result = await _tenantService.CancelTenantAsync(id, cancelDate);
            return Ok(result);
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error cancelling Tenant with ID {Id}", id);
            return StatusCode(500, "An error occurred while processing your request.");
        }
    }
}