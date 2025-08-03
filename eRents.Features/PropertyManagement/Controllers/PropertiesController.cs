using eRents.Domain.Models;
using eRents.Features.Core.Controllers;
using eRents.Features.PropertyManagement.DTOs;
using eRents.Features.PropertyManagement.Services;
using eRents.Features.Shared.Attributes;
using eRents.Features.Shared.DTOs;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;

namespace eRents.Features.PropertyManagement.Controllers;

/// <summary>
/// Properties Controller implementing CRUD abstraction pattern
/// Handles property management endpoints
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Authorize]
public class PropertiesController : CrudController<Property, PropertyRequest, PropertyResponse, PropertySearchObject>
{
    private readonly IPropertyService _propertyService;

    public PropertiesController(
        IPropertyService propertyService,
        ILogger<PropertiesController> logger) : base(propertyService, logger)
    {
        _propertyService = propertyService;
    }

    #region Custom Property Endpoints

    /// <summary>
    /// Get properties with basic search (simplified filters for regular users)
    /// </summary>
    [HttpGet("basic-search")]
    [AllowAnonymous]
    public async Task<ActionResult<PagedResponse<PropertyResponse>>> GetPropertiesBasicSearch([FromQuery] BasicPropertySearch search)
    {
        try
        {
            var propertySearch = new PropertySearchObject
            {
                SearchText = search.SearchText,
                City = search.CityName,
                MinPrice = search.MinPrice,
                MaxPrice = search.MaxPrice,
                PropertyType = search.PropertyTypeId,
                Page = search.Page,
                PageSize = search.PageSize,
                SortBy = search.SortBy,
                SortDescending = search.SortDescending
            };

            var result = await _propertyService.GetPagedAsync(propertySearch);
            return Ok(result);
        }
        catch (Exception ex)
        {
            return HandleException(ex, "Error retrieving properties with basic search");
        }
    }

    /// <summary>
    /// Get properties with advanced search (comprehensive filters for power users)
    /// </summary>
    [HttpGet("advanced-search")]
    [AllowAnonymous]
    public async Task<ActionResult<PagedResponse<PropertyResponse>>> GetPropertiesAdvancedSearch([FromQuery] AdvancedPropertySearch search)
    {
        try
        {
            var propertySearch = new PropertySearchObject
            {
                SearchText = search.SearchText,
                City = search.City,
                State = search.State,
                MinPrice = search.MinPrice,
                MaxPrice = search.MaxPrice,
                Bedrooms = search.Bedrooms,
                Page = search.Page,
                PageSize = search.PageSize,
                SortBy = search.SortBy,
                SortDescending = search.SortDescending
            };

            var result = await _propertyService.GetPagedAsync(propertySearch);
            return Ok(result);
        }
        catch (Exception ex)
        {
            return HandleException(ex, "Error retrieving properties with advanced search");
        }
    }

    /// <summary>
    /// Update property status
    /// </summary>
    [HttpPut("{id}/status")]
    [Authorize(Roles = "Landlord,Admin")]
    public async Task<ActionResult> UpdatePropertyStatus(int id, [FromBody] PropertyStatusUpdateRequest request)
    {
        try
        {
            await _propertyService.UpdateStatusAsync(id, request.StatusId);
            return Ok(new { Message = "Property status updated successfully" });
        }
        catch (Exception ex)
        {
            return HandleException(ex, "Error updating property status");
        }
    }

    /// <summary>
    /// Get properties owned by the current user
    /// </summary>
    [HttpGet("my")]
    [Authorize(Roles = "Landlord,Admin")]
    public async Task<ActionResult<PagedResponse<PropertyResponse>>> GetMyProperties([FromQuery] PropertySearchObject? search = null)
    {
        try
        {
            var result = await _propertyService.GetMyPropertiesAsync(search);
            return Ok(result);
        }
        catch (Exception ex)
        {
            return HandleException(ex, "Error retrieving my properties");
        }
    }

    /// <summary>
    /// Get properties by rental type
    /// </summary>
    [HttpGet("rental-type/{rentalType}")]
    [AllowAnonymous]
    public async Task<ActionResult<PagedResponse<PropertyResponse>>> GetPropertiesByRentalType(string rentalType, [FromQuery] PropertySearchObject? search = null)
    {
        try
        {
            var result = await _propertyService.GetPropertiesByRentalTypeAsync(rentalType, search);
            return Ok(result);
        }
        catch (Exception ex)
        {
            return HandleException(ex, "Error retrieving properties by rental type");
        }
    }

    /// <summary>
    /// Get property availability for date range
    /// </summary>
    [HttpGet("{id}/availability")]
    [AllowAnonymous]
    public async Task<ActionResult<PropertyAvailabilityResponse>> GetPropertyAvailability(int id, 
        [FromQuery] DateTime? start = null, [FromQuery] DateTime? end = null)
    {
        try
        {
            var result = await _propertyService.GetAvailabilityAsync(id, start, end);
            return Ok(result);
        }
        catch (Exception ex)
        {
            return HandleException(ex, "Error retrieving property availability");
        }
    }

    /// <summary>
    /// Check if property can accept bookings
    /// </summary>
    [HttpGet("{id}/can-accept-bookings")]
    [AllowAnonymous]
    public async Task<ActionResult<bool>> CanPropertyAcceptBookings(int id)
    {
        try
        {
            var result = await _propertyService.CanPropertyAcceptBookingsAsync(id);
            return Ok(result);
        }
        catch (Exception ex)
        {
            return HandleException(ex, "Error checking if property can accept bookings");
        }
    }

    /// <summary>
    /// Check if property is visible in market
    /// </summary>
    [HttpGet("{id}/is-visible")]
    [AllowAnonymous]
    public async Task<ActionResult<bool>> IsPropertyVisibleInMarket(int id)
    {
        try
        {
            var result = await _propertyService.IsPropertyVisibleInMarketAsync(id);
            return Ok(result);
        }
        catch (Exception ex)
        {
            return HandleException(ex, "Error checking if property is visible in market");
        }
    }

    /// <summary>
    /// Check if property has active annual tenant
    /// </summary>
    [HttpGet("{id}/has-active-annual-tenant")]
    [Authorize(Roles = "Landlord,Admin")]
    public async Task<ActionResult<bool>> HasActiveAnnualTenant(int id)
    {
        try
        {
            var result = await _propertyService.HasActiveAnnualTenantAsync(id);
            return Ok(result);
        }
        catch (Exception ex)
        {
            return HandleException(ex, "Error checking if property has active annual tenant");
        }
    }

    /// <summary>
    /// Search properties with filters
    /// </summary>
    [HttpPost("search")]
    [AllowAnonymous]
    public async Task<ActionResult<PagedResponse<PropertyResponse>>> SearchProperties(PropertySearchObject search)
    {
        try
        {
            var result = await _propertyService.SearchPropertiesAsync(search);
            return Ok(result);
        }
        catch (Exception ex)
        {
            return HandleException(ex, "Error searching properties");
        }
    }

    /// <summary>
    /// Get popular properties
    /// </summary>
    [HttpGet("popular")]
    [AllowAnonymous]
    public async Task<ActionResult<List<PropertyResponse>>> GetPopularProperties([FromQuery] int limit = 10)
    {
        try
        {
            var result = await _propertyService.GetPopularPropertiesAsync(limit);
            return Ok(result);
        }
        catch (Exception ex)
        {
            return HandleException(ex, "Error retrieving popular properties");
        }
    }

    /// <summary>
    /// Save property to user's saved properties list
    /// </summary>
    [HttpPost("{id}/save")]
    [Authorize]
    public async Task<ActionResult<bool>> SaveProperty(int id)
    {
        try
        {
            var userId = GetCurrentUserId();
            var result = await _propertyService.SavePropertyAsync(id, userId);
            return Ok(result);
        }
        catch (Exception ex)
        {
            return HandleException(ex, "Error saving property");
        }
    }

    #endregion

    #region Helper Methods

    /// <summary>
    /// Get current user ID from claims
    /// </summary>
    private int GetCurrentUserId()
    {
        var userIdClaim = User.FindFirst("userId");
        if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out var userId))
            throw new UnauthorizedAccessException("Invalid user ID");

        return userId;
    }

    #endregion
}
