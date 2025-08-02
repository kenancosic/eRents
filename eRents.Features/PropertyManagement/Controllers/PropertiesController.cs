using eRents.Features.PropertyManagement.DTOs;
using eRents.Features.PropertyManagement.Services;
using eRents.Features.Shared.DTOs;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;

namespace eRents.Features.PropertyManagement.Controllers;

/// <summary>
/// PropertyController - New Feature-Based Architecture
/// Maintains API compatibility with existing endpoints
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Authorize]
public class PropertiesController : ControllerBase
{
	private readonly IPropertyManagementService _propertyService;
	private readonly ILogger<PropertiesController> _logger;

	public PropertiesController(
			IPropertyManagementService propertyService,
			ILogger<PropertiesController> logger)
	{
		_propertyService = propertyService;
		_logger = logger;
	}

	#region Core CRUD Endpoints

	/// <summary>
	/// Get all properties with filtering and pagination
	/// GET /api/properties
	/// </summary>
	[HttpGet]
	[AllowAnonymous] // Allow anonymous access for property browsing
	public async Task<ActionResult<PagedResponse<PropertyResponse>>> GetProperties([FromQuery] PropertySearchObject search)
	{
		try
		{
			search ??= new PropertySearchObject();
			var result = await _propertyService.GetPropertiesAsync(search);
			return Ok(result);
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error getting properties");
			return StatusCode(500, new { message = "Internal server error" });
		}
	}

	/// <summary>
	/// Get properties with basic search filters only - simplified interface
	/// GET /api/properties/basic-search
	/// </summary>
	[HttpGet("basic-search")]
	[AllowAnonymous]
	public async Task<ActionResult<PagedResponse<PropertyResponse>>> GetPropertiesBasicSearch([FromQuery] BasicPropertySearch search)
	{
		try
		{
			search ??= new BasicPropertySearch();
			
			// Convert BasicPropertySearch to PropertySearchObject for service compatibility
			var fullSearch = new PropertySearchObject
			{
				// Map pagination
				Page = search.Page,
				PageSize = search.PageSize,
				NoPaging = search.NoPaging,
				
				// Map basic search
				SearchTerm = search.SearchTerm,
				SearchText = search.SearchText,
				GenericStatusString = search.GenericStatusString,
				
				// Map core property filters
				Name = search.Name,
				MinPrice = search.MinPrice,
				MaxPrice = search.MaxPrice,
				PropertyTypeId = search.PropertyTypeId,
				CityName = search.CityName,
				Bedrooms = search.Bedrooms,
				
				// Map sorting
				SortBy = search.SortBy,
				SortDescending = search.SortDescending,
				
				// Set performance-optimized defaults for basic search
				IncludeImages = false,
				IncludeAmenities = false,
				IncludeReviews = false,
				IncludeOwner = false
			};
			
			var result = await _propertyService.GetPropertiesAsync(fullSearch);
			return Ok(result);
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error getting properties with basic search");
			return StatusCode(500, new { message = "Internal server error" });
		}
	}

	/// <summary>
	/// Get properties with advanced search filters - full feature set
	/// GET /api/properties/advanced-search
	/// </summary>
	[HttpGet("advanced-search")]
	[AllowAnonymous]
	public async Task<ActionResult<PagedResponse<PropertyResponse>>> GetPropertiesAdvancedSearch([FromQuery] AdvancedPropertySearch search)
	{
		try
		{
			search ??= new AdvancedPropertySearch();
			
			// Convert AdvancedPropertySearch to PropertySearchObject for service compatibility
			var fullSearch = new PropertySearchObject
			{
				// Map pagination from base
				Page = search.Page,
				PageSize = search.PageSize,
				NoPaging = search.NoPaging,
				
				// Map basic search from base
				SearchTerm = search.SearchTerm,
				SearchText = search.SearchText,
				GenericStatusString = search.GenericStatusString,
				
				// Map available properties from AdvancedPropertySearch (simplified version)
				MinPrice = search.MinPrice,
				MaxPrice = search.MaxPrice,
				Bedrooms = search.Bedrooms,
				CityName = search.City,
				StateName = search.State,
				
				// Map sorting
				SortBy = search.SortBy,
				SortDescending = search.SortDescending,
				
				// Set reasonable defaults for advanced features not available in simplified search
				IncludeImages = true,
				IncludeAmenities = false,
				IncludeReviews = false,
				IncludeOwner = false
			};
			
			var result = await _propertyService.GetPropertiesAsync(fullSearch);
			return Ok(result);
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error getting properties with advanced search");
			return StatusCode(500, new { message = "Internal server error" });
		}
	}

	/// <summary>
	/// Get property by ID
	/// GET /api/properties/{id}
	/// </summary>
	[HttpGet("{id:int}")]
	[AllowAnonymous] // Allow anonymous access to view property details
	public async Task<ActionResult<PropertyResponse>> GetProperty(int id)
	{
		try
		{
			var property = await _propertyService.GetPropertyByIdAsync(id);
			if (property == null)
			{
				return NotFound(new { message = "Property not found" });
			}

			return Ok(property);
		}
		catch (UnauthorizedAccessException)
		{
			return Forbid();
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error getting property {PropertyId}", id);
			return StatusCode(500, new { message = "Internal server error" });
		}
	}

	/// <summary>
	/// Create new property
	/// POST /api/properties
	/// </summary>
	[HttpPost]
	[Authorize(Roles = "Landlord")]
	public async Task<ActionResult<PropertyResponse>> CreateProperty([FromBody] PropertyRequest request)
	{
		try
		{
			if (!ModelState.IsValid)
			{
				return BadRequest(ModelState);
			}

			var result = await _propertyService.CreatePropertyAsync(request);
			return CreatedAtAction(nameof(GetProperty), new { id = result.PropertyId }, result);
		}
		catch (ArgumentException ex)
		{
			return BadRequest(new { message = ex.Message });
		}
		catch (UnauthorizedAccessException)
		{
			return Forbid();
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error creating property");
			return StatusCode(500, new { message = "Internal server error" });
		}
	}

	/// <summary>
	/// Update existing property
	/// PUT /api/properties/{id}
	/// </summary>
	[HttpPut("{id:int}")]
	[Authorize(Roles = "Landlord")]
	public async Task<ActionResult<PropertyResponse>> UpdateProperty(int id, [FromBody] PropertyRequest request)
	{
		try
		{
			if (!ModelState.IsValid)
			{
				return BadRequest(ModelState);
			}

			var result = await _propertyService.UpdatePropertyAsync(id, request);
			return Ok(result);
		}
		catch (NotFoundException)
		{
			return NotFound(new { message = "Property not found" });
		}
		catch (ArgumentException ex)
		{
			return BadRequest(new { message = ex.Message });
		}
		catch (UnauthorizedAccessException)
		{
			return Forbid();
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error updating property {PropertyId}", id);
			return StatusCode(500, new { message = "Internal server error" });
		}
	}

	/// <summary>
	/// Delete property
	/// DELETE /api/properties/{id}
	/// </summary>
	[HttpDelete("{id:int}")]
	[Authorize(Roles = "Landlord")]
	public async Task<ActionResult> DeleteProperty(int id)
	{
		try
		{
			var result = await _propertyService.DeletePropertyAsync(id);
			if (!result)
			{
				return NotFound(new { message = "Property not found" });
			}

			return NoContent();
		}
		catch (UnauthorizedAccessException)
		{
			return Forbid();
		}
		catch (InvalidOperationException ex)
		{
			return BadRequest(new { message = ex.Message });
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error deleting property {PropertyId}", id);
			return StatusCode(500, new { message = "Internal server error" });
		}
	}

	#endregion

	#region Business Logic Endpoints

	/// <summary>
	/// Update property status
	/// PUT /api/properties/{id}/status
	/// </summary>
	[HttpPut("{id:int}/status")]
	[Authorize(Roles = "Landlord")]
	public async Task<ActionResult> UpdatePropertyStatus(int id, [FromBody] UpdatePropertyStatusRequest request)
	{
		try
		{
			if (!ModelState.IsValid)
			{
				return BadRequest(ModelState);
			}

			await _propertyService.UpdateStatusAsync(id, request.Status);
			return NoContent();
		}
		catch (NotFoundException)
		{
			return NotFound(new { message = "Property not found" });
		}
		catch (UnauthorizedAccessException)
		{
			return Forbid();
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error updating property {PropertyId} status", id);
			return StatusCode(500, new { message = "Internal server error" });
		}
	}

	/// <summary>
	/// Get properties owned by current user with pagination
	/// GET /api/properties/my-properties
	/// </summary>
	[HttpGet("my-properties")]
	[Authorize(Roles = "Landlord")]
	public async Task<ActionResult<PagedResponse<PropertyResponse>>> GetMyProperties([FromQuery] PropertySearchObject? search)
	{
		try
		{
			var result = await _propertyService.GetMyPropertiesAsync(search);
			return Ok(result);
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error getting current user's properties");
			return StatusCode(500, new { message = "Internal server error" });
		}
	}

	/// <summary>
	/// Get properties by rental type with pagination
	/// GET /api/properties/rental-type/{rentalType}
	/// </summary>
	[HttpGet("rental-type/{rentalType}")]
	[AllowAnonymous]
	public async Task<ActionResult<PagedResponse<PropertyResponse>>> GetPropertiesByRentalType(
			string rentalType,
			[FromQuery] PropertySearchObject? search)
	{
		try
		{
			var result = await _propertyService.GetPropertiesByRentalTypeAsync(rentalType, search);
			return Ok(result);
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error getting properties by rental type {RentalType}", rentalType);
			return StatusCode(500, new { message = "Internal server error" });
		}
	}

	/// <summary>
	/// Check property availability for date range
	/// GET /api/properties/{id}/availability
	/// </summary>
	[HttpGet("{id:int}/availability")]
	[AllowAnonymous]
	public async Task<ActionResult<PropertyAvailabilityResponse>> GetPropertyAvailability(
			int id,
			[FromQuery] DateTime? startDate,
			[FromQuery] DateTime? endDate)
	{
		try
		{
			var result = await _propertyService.GetAvailabilityAsync(id, startDate, endDate);
			return Ok(result);
		}
		catch (NotFoundException)
		{
			return NotFound(new { message = "Property not found" });
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error checking availability for property {PropertyId}", id);
			return StatusCode(500, new { message = "Internal server error" });
		}
	}

	/// <summary>
	/// Check if property can accept bookings
	/// GET /api/properties/{id}/can-accept-bookings
	/// </summary>
	[HttpGet("{id:int}/can-accept-bookings")]
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
			_logger.LogError(ex, "Error checking if property {PropertyId} can accept bookings", id);
			return StatusCode(500, new { message = "Internal server error" });
		}
	}

	/// <summary>
	/// Check if property is visible in market
	/// GET /api/properties/{id}/is-visible
	/// </summary>
	[HttpGet("{id:int}/is-visible")]
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
			_logger.LogError(ex, "Error checking if property {PropertyId} is visible", id);
			return StatusCode(500, new { message = "Internal server error" });
		}
	}

	/// <summary>
	/// Check if property has active annual tenant
	/// GET /api/properties/{id}/has-active-tenant
	/// </summary>
	[HttpGet("{id:int}/has-active-tenant")]
	[Authorize(Roles = "Landlord")]
	public async Task<ActionResult<bool>> HasActiveAnnualTenant(int id)
	{
		try
		{
			var result = await _propertyService.HasActiveAnnualTenantAsync(id);
			return Ok(result);
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error checking if property {PropertyId} has active tenant", id);
			return StatusCode(500, new { message = "Internal server error" });
		}
	}

	/// <summary>
	/// Search properties with advanced filtering
	/// GET /api/properties/search
	/// </summary>
	[HttpGet("search")]
	[AllowAnonymous]
	public async Task<ActionResult<PagedResponse<PropertyResponse>>> SearchProperties([FromQuery] PropertySearchObject search)
	{
		try
		{
			search ??= new PropertySearchObject();
			var result = await _propertyService.SearchPropertiesAsync(search);
			return Ok(result);
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error searching properties");
			return StatusCode(500, new { message = "Internal server error" });
		}
	}

	/// <summary>
	/// Get popular properties based on bookings and ratings
	/// GET /api/properties/popular
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
			_logger.LogError(ex, "Error getting popular properties");
			return StatusCode(500, new { message = "Internal server error" });
		}
	}

	#endregion
}

/// <summary>
/// Request model for updating property status
/// </summary>
public class UpdatePropertyStatusRequest
{
	public int Status { get; set; }
}