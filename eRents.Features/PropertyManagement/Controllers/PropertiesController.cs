using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using eRents.Features.PropertyManagement.Models;
using eRents.Domain.Models;
using eRents.Features.Core;
using System.Threading.Tasks;
using eRents.Features.PropertyManagement.Services;
using System.Security.Claims;
using System.Collections.Generic;
using eRents.Features.LookupManagement.Models;

namespace eRents.Features.PropertyManagement.Controllers;

[Route("api/[controller]")]
[ApiController]
public class PropertiesController : CrudController<Property, PropertyRequest, PropertyResponse, PropertySearch>
{
    private readonly PropertyService _propertyService;
    private readonly IPropertyRecommendationService _recommendationService;
    private readonly PropertyAvailabilityService _propertyAvailabilityService;
    private readonly ILogger<PropertiesController> _logger;

    public PropertiesController(
            ICrudService<Property, PropertyRequest, PropertyResponse, PropertySearch> service,
            ILogger<PropertiesController> logger,
            IPropertyRecommendationService recommendationService,
            PropertyAvailabilityService propertyAvailabilityService)
            : base(service, logger)
    {
        _propertyService = service as PropertyService ?? throw new System.InvalidOperationException("PropertyService not registered correctly");
        _recommendationService = recommendationService;
        _propertyAvailabilityService = propertyAvailabilityService;
    }

    /// <summary>
    /// Batch endpoint returning property cards for a list of property IDs.
    /// </summary>
    [HttpPost("cards/batch")]
    public async Task<ActionResult<List<PropertyCardResponse>>> GetCardsBatch([FromBody] BatchIdsRequest request)
    {
        try
        {
            if (request == null || request.Ids == null || request.Ids.Count == 0)
            {
                return BadRequest(new { Message = "Ids must be provided" });
            }

            var cards = await _propertyService.GetPropertyCardsByIdsAsync(request.Ids);
            return Ok(cards);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching property cards batch");
            return StatusCode(500, new { Message = "An error occurred while fetching property cards" });
        }
    }

    [HttpGet("{id}/current-tenant")]
    public async Task<ActionResult<PropertyTenantSummary>> GetCurrentTenant(int id)
    {
        var summary = await _propertyService.GetCurrentTenantSummaryAsync(id);
        if (summary == null)
            return NoContent();
        return Ok(summary);
    }

    [HttpPut("{id}/status")]
    public async Task<ActionResult<PropertyResponse>> UpdatePropertyStatus(int id, [FromBody] PropertyStatusUpdateRequest request)
    {
        try
        {
            var result = await _propertyService.UpdatePropertyStatusAsync(id, request.Status, request.UnavailableFrom, request.UnavailableTo);
            return Ok(result);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating property status for property {PropertyId}", id);
            return StatusCode(500, new { message = "An error occurred while updating property status" });
        }
    }

    

    /// <summary>
    /// Get property recommendations for the current authenticated user
    /// </summary>
    /// <param name="count">The number of recommendations to return (default: 10)</param>
    /// <returns>A list of recommended properties</returns>
    [HttpGet("me/recommendations")]
    public async Task<ActionResult<List<PropertyCardResponse>>> GetMyRecommendations([FromQuery] int count = 10)
    {
        try
        {
            var userId = GetCurrentUserId();
            if (userId == null) return Unauthorized();

            var recommendations = await _recommendationService.GetRecommendationsAsync(userId.Value, count);
            var ids = recommendations.Select(r => r.PropertyId).Distinct().ToList();

            // Project to card DTOs
            var cards = await _propertyService.GetPropertyCardsByIdsAsync(ids);

            // Preserve original recommendation order
            var order = ids.Select((id, idx) => new { id, idx }).ToDictionary(x => x.id, x => x.idx);
            var sorted = cards
                .OrderBy(c => order[(int)c.GetType().GetProperty("PropertyId")!.GetValue(c)!])
                .ToList();

            return Ok(sorted);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { Message = "An error occurred while generating recommendations", Error = ex.Message });
        }
    }

    

    /// <summary>
    /// Get similar properties for a specific property based on ML predictions
    /// </summary>
    /// <param name="id">The property ID to find similar properties for</param>
    /// <param name="count">The number of similar properties to return (default: 4)</param>
    /// <returns>A list of similar properties</returns>
    [HttpGet("{id}/similar")]
    public async Task<ActionResult<List<PropertyCardResponse>>> GetSimilarProperties(int id, [FromQuery] int count = 4)
    {
        try
        {
            var userId = GetCurrentUserId();
            if (userId == null) return Unauthorized();

            var recommendations = await _recommendationService.GetSimilarPropertiesAsync(userId.Value, id, count);
            var ids = recommendations.Select(r => r.PropertyId).Distinct().ToList();

            if (ids.Count == 0)
            {
                return Ok(new List<PropertyCardResponse>());
            }

            // Project to card DTOs
            var cards = await _propertyService.GetPropertyCardsByIdsAsync(ids);

            // Preserve original recommendation order
            var order = ids.Select((propId, idx) => new { propId, idx }).ToDictionary(x => x.propId, x => x.idx);
            var sorted = cards
                .OrderBy(c => order[(int)c.GetType().GetProperty("PropertyId")!.GetValue(c)!])
                .ToList();

            return Ok(sorted);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting similar properties for property {PropertyId}", id);
            return StatusCode(500, new { Message = "An error occurred while getting similar properties", Error = ex.Message });
        }
    }

    /// <summary>
    /// Checks if a property is available for the specified date range
    /// </summary>
    [HttpGet("{id}/check-availability")]
    public async Task<ActionResult<bool>> CheckAvailability(int id, [FromQuery] DateTime startDate, [FromQuery] DateTime endDate)
    {
        try
        {
            var isAvailable = await _propertyAvailabilityService.CheckAvailabilityAsync(id, startDate, endDate);
            return Ok(isAvailable);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error checking availability for property {PropertyId}", id);
            return StatusCode(500, "An error occurred while checking availability");
        }
    }

    /// <summary>
    /// Gets availability data for a property within a date range
    /// </summary>
    [HttpGet("{id}/availability")]
    public async Task<ActionResult<AvailabilityRangeResponse>> GetAvailability(int id, [FromQuery] DateTime startDate, [FromQuery] DateTime endDate)
    {
        try
        {
            var availability = await _propertyAvailabilityService.GetAvailabilityDataAsync(id, startDate, endDate);
            return Ok(availability);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting availability data for property {PropertyId}", id);
            return StatusCode(500, "An error occurred while getting availability data");
        }
    }

    /// <summary>
    /// Calculates price estimate for a booking
    /// </summary>
    [HttpPost("{id}/price-estimate")]
    public async Task<ActionResult<PricingEstimateResponse>> CalculatePriceEstimate(int id, [FromBody] PricingEstimateRequest request)
    {
        try
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            if (!request.Validate())
            {
                return BadRequest("Invalid date range or guest count");
            }

            var estimate = await _propertyAvailabilityService.CalculatePriceEstimateAsync(id, request.StartDate, request.EndDate, request.Guests);
            return Ok(estimate);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error calculating price estimate for property {PropertyId}", id);
            return StatusCode(500, "An error occurred while calculating price estimate");
        }
    }

    // Helper to read current user id as int from claims (aligns with Domain expecting int keys)
    private int? GetCurrentUserId()
    {
        var idClaim = User.FindFirst(ClaimTypes.NameIdentifier) ?? User.FindFirst("sub") ?? User.FindFirst("userId");
        if (idClaim == null) return null;
        return int.TryParse(idClaim.Value, out var id) ? id : null;
    }
}