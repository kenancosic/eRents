using eRents.Features.UserManagement.DTOs;
using eRents.Features.UserManagement.Services;
using eRents.Features.Shared.DTOs;
using eRents.Features.Shared.Controllers;
using eRents.Domain.Shared.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;

namespace eRents.Features.UserManagement.Controllers;

/// <summary>
/// Tenant Management Controller following modular architecture
/// Clean separation with UserManagement feature services and DTOs
/// Handles tenant relationships, preferences, and status operations
/// Updated to use consolidated UserService
/// </summary>
[Route("api/[controller]")]
[Authorize] // All endpoints require authentication
public class TenantController : BaseController
{
	private readonly IUserService _userService;
	private readonly ICurrentUserService _currentUserService;
	private readonly ILogger<TenantController> _logger;

	public TenantController(
			IUserService userService,
			ICurrentUserService currentUserService,
			ILogger<TenantController> logger)
	{
		_userService = userService;
		_currentUserService = currentUserService;
		_logger = logger;
	}

	#region Current Tenants Management

	/// <summary>
	/// Get current tenants for the authenticated landlord with pagination
	/// Returns tenants who have active leases in landlord's properties
	/// </summary>
	/// <param name="search">Search and pagination parameters</param>
	/// <returns>Paginated list of current tenants</returns>
	[HttpGet("current")]
	[Authorize(Roles = "Landlord")]
	public async Task<ActionResult<PagedResponse<TenantResponse>>> GetCurrentTenants([FromQuery] TenantSearchObject search)
	{
		return await GetPagedAsync(search, _userService.GetCurrentTenantsAsync, _logger, nameof(GetCurrentTenants));
	}

	/// <summary>
	/// Get details of a specific current tenant
	/// Validates that tenant is in landlord's properties before returning data
	/// </summary>
	/// <param name="tenantId">ID of the tenant</param>
	/// <returns>Detailed tenant information</returns>
	[HttpGet("current/{tenantId}")]
	[Authorize(Roles = "Landlord")]
	public async Task<ActionResult<TenantResponse>> GetTenantById(int tenantId)
	{
		return await GetByIdAsync(tenantId, _userService.GetTenantByIdAsync, _logger, nameof(GetTenantById));
	}

	#endregion

	#region Prospective Tenant Discovery

	/// <summary>
	/// Browse prospective tenants based on their search preferences
	/// Allows landlords to discover tenants actively looking for properties
	/// </summary>
	/// <param name="search">Filtering and pagination options</param>
	/// <returns>Paginated list of tenant preferences for prospective tenant discovery</returns>

	#endregion

	#region Tenant Relationships & Performance

	/// <summary>
	/// Get tenant relationships with performance metrics for landlord
	/// Returns comprehensive tenant relationship data with business metrics
	/// </summary>
	/// <returns>List of tenant relationships with performance data</returns>
	[HttpGet("relationships")]
	[Authorize(Roles = "Landlord")]
	public async Task<ActionResult<List<TenantRelationshipResponse>>> GetTenantRelationships()
	{
		return await GetListAsync(_userService.GetTenantRelationshipsForLandlordAsync, _logger, nameof(GetTenantRelationships));
	}

	/// <summary>
	/// Get current property assignments for specified tenants
	/// Returns mapping of tenants to their current property assignments
	/// </summary>
	/// <param name="tenantIds">List of tenant IDs to get assignments for</param>
	/// <returns>Dictionary mapping tenant IDs to property assignments</returns>
	[HttpGet("assignments")]
	[Authorize(Roles = "Landlord")]
	public async Task<ActionResult<Dictionary<int, TenantPropertyAssignmentResponse>>> GetTenantPropertyAssignments([FromQuery] List<int> tenantIds)
	{
		try
		{
			if (tenantIds == null || !tenantIds.Any())
			{
				return BadRequest("Tenant IDs are required");
			}

			var assignments = await _userService.GetTenantPropertyAssignmentsAsync(tenantIds);

			_logger.LogInformation("Retrieved {AssignmentCount} tenant property assignments for landlord {LandlordId}",
					assignments.Count, _currentUserService.UserId);

			return Ok(assignments);
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error retrieving tenant property assignments for user {UserId}", _currentUserService.UserId);
			return StatusCode(500, "An error occurred while retrieving tenant property assignments");
		}
	}

	#endregion

	#region Tenant Status Operations

	/// <summary>
	/// Check if property has active tenant
	/// Utility endpoint for property availability checking
	/// </summary>
	/// <param name="propertyId">ID of the property to check</param>
	/// <returns>Boolean indicating if property has active tenant</returns>
	[HttpGet("property/{propertyId}/has-active-tenant")]
	[Authorize(Roles = "Landlord")]
	public async Task<ActionResult<bool>> HasActiveTenant(int propertyId)
	{
		try
		{
			var hasActiveTenant = await _userService.HasActiveTenantAsync(propertyId);

			_logger.LogDebug("Property {PropertyId} active tenant check: {HasTenant}", propertyId, hasActiveTenant);

			return Ok(hasActiveTenant);
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error checking active tenant for property {PropertyId}", propertyId);
			return StatusCode(500, "An error occurred while checking property tenant status");
		}
	}

	/// <summary>
	/// Get current monthly rent for tenant
	/// Returns the current rental amount for the specified tenant
	/// </summary>
	/// <param name="tenantId">ID of the tenant</param>
	/// <returns>Current monthly rent amount</returns>
	[HttpGet("{tenantId}/monthly-rent")]
	[Authorize(Roles = "Landlord")]
	public async Task<ActionResult<decimal>> GetCurrentMonthlyRent(int tenantId)
	{
		try
		{
			var monthlyRent = await _userService.GetCurrentMonthlyRentAsync(tenantId);

			_logger.LogDebug("Retrieved monthly rent for tenant {TenantId}: {Rent}", tenantId, monthlyRent);

			return Ok(monthlyRent);
		}
		catch (ArgumentException ex)
		{
			_logger.LogWarning(ex, "Tenant {TenantId} not found or invalid", tenantId);
			return NotFound(ex.Message);
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error retrieving monthly rent for tenant {TenantId}", tenantId);
			return StatusCode(500, "An error occurred while retrieving monthly rent");
		}
	}

	/// <summary>
	/// Create tenant from approved rental request
	/// Creates a new tenant record when a rental request is approved
	/// Note: This is a SoC violation that should be moved to TenantCreationService
	/// </summary>
	/// <param name="request">Tenant creation request data</param>
	/// <returns>Created tenant information</returns>
	[HttpPost("create-from-rental-request")]
	[Authorize(Roles = "Landlord")]
	public async Task<ActionResult<TenantResponse>> CreateTenantFromApprovedRentalRequest([FromBody] TenantCreateRequest request)
	{
		return await CreateAsync(request, _userService.CreateTenantFromApprovedRentalRequestAsync, _logger, nameof(CreateTenantFromApprovedRentalRequest),
			tenant => CreatedAtAction(nameof(GetTenantById), new { tenantId = tenant.TenantId }, tenant));
	}

	#endregion

	#region Lease Status Checks

	/// <summary>
	/// Check if tenant's lease is expiring within specified days
	/// Delegates to LeaseCalculationService for business logic
	/// </summary>
	/// <param name="tenantId">ID of the tenant</param>
	/// <param name="days">Number of days to check ahead for expiration</param>
	/// <returns>Boolean indicating if lease is expiring</returns>
	[HttpGet("{tenantId}/lease-expiring/{days}")]
	[Authorize(Roles = "Landlord")]
	public async Task<ActionResult<bool>> IsLeaseExpiringInDays(int tenantId, int days)
	{
		try
		{
			var isExpiring = await _userService.IsLeaseExpiringInDaysAsync(tenantId, days);

			_logger.LogDebug("Lease expiration check for tenant {TenantId} in {Days} days: {IsExpiring}",
					tenantId, days, isExpiring);

			return Ok(isExpiring);
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error checking lease expiration for tenant {TenantId}", tenantId);
			return StatusCode(500, "An error occurred while checking lease expiration");
		}
	}

	/// <summary>
	/// Get tenants with expiring leases for landlord
	/// Delegates to LeaseCalculationService for business logic
	/// </summary>
	/// <param name="daysAhead">Number of days ahead to check for expiring leases</param>
	/// <returns>List of tenants with expiring leases</returns>
	[HttpGet("expiring-leases/{daysAhead}")]
	[Authorize(Roles = "Landlord")]
	public async Task<ActionResult<List<TenantResponse>>> GetTenantsWithExpiringLeases(int daysAhead)
	{
		try
		{
			var landlordId = _currentUserService.GetUserIdAsInt();
			if (landlordId == 0)
			{
				return Unauthorized();
			}

			var expiringTenants = await _userService.GetTenantsWithExpiringLeasesAsync(landlordId.Value, daysAhead);

			_logger.LogInformation("Found {Count} tenants with expiring leases for landlord {LandlordId}",
					expiringTenants.Count, landlordId);

			return Ok(expiringTenants);
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error retrieving tenants with expiring leases for user {UserId}", _currentUserService.UserId);
			return StatusCode(500, "An error occurred while retrieving tenants with expiring leases");
		}
	}

	#endregion
}