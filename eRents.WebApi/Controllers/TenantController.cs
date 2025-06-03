using eRents.Application.Service.TenantService;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Shared.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace eRents.WebApi.Controllers
{
    /// <summary>
    /// Tenant Management Controller for Landlord Operations
    /// Provides comprehensive tenant relationship management, prospective tenant discovery,
    /// and tenant feedback system for property management professionals
    /// </summary>
    [ApiController]
    [Route("[controller]")]
    [Authorize] // All endpoints require authentication
    public class TenantController : ControllerBase
    {
        private readonly ITenantService _tenantService;
        private readonly ICurrentUserService _currentUserService;

        public TenantController(ITenantService tenantService, ICurrentUserService currentUserService)
        {
            _tenantService = tenantService;
            _currentUserService = currentUserService;
        }

        /// <summary>
        /// Get current tenants for the authenticated landlord
        /// Returns tenants who have active bookings in landlord's properties
        /// </summary>
        /// <param name="queryParams">Optional filtering and search parameters</param>
        /// <returns>List of current tenants with user details</returns>
        [HttpGet("current")]
        [Authorize(Roles = "Landlord")]
        public async Task<ActionResult<List<UserResponse>>> GetCurrentTenants([FromQuery] Dictionary<string, string>? queryParams = null)
        {
            try
            {
                var tenants = await _tenantService.GetCurrentTenantsAsync(queryParams);
                return Ok(tenants);
            }
            catch (UnauthorizedAccessException)
            {
                return Forbid("You can only access tenants in your properties");
            }
            catch (Exception ex)
            {
                return BadRequest($"Error retrieving current tenants: {ex.Message}");
            }
        }

        /// <summary>
        /// Get details of a specific current tenant
        /// Validates that tenant is in landlord's properties before returning data
        /// </summary>
        /// <param name="tenantId">ID of the tenant</param>
        /// <returns>Detailed tenant information</returns>
        [HttpGet("current/{tenantId}")]
        [Authorize(Roles = "Landlord")]
        public async Task<ActionResult<UserResponse>> GetTenantById(int tenantId)
        {
            try
            {
                var tenant = await _tenantService.GetTenantByIdAsync(tenantId);
                if (tenant == null)
                    return NotFound("Tenant not found");

                return Ok(tenant);
            }
            catch (UnauthorizedAccessException)
            {
                return Forbid("You can only access tenants in your properties");
            }
            catch (Exception ex)
            {
                return BadRequest($"Error retrieving tenant details: {ex.Message}");
            }
        }

        /// <summary>
        /// Browse prospective tenants based on their search preferences
        /// Allows landlords to discover tenants actively looking for properties
        /// </summary>
        /// <param name="queryParams">Filtering options (city, price range, amenities, etc.)</param>
        /// <returns>List of tenant preferences for prospective tenant discovery</returns>
        [HttpGet("prospective")]
        [Authorize(Roles = "Landlord")]
        public async Task<ActionResult<List<TenantPreferenceResponse>>> GetProspectiveTenants([FromQuery] Dictionary<string, string>? queryParams = null)
        {
            try
            {
                var prospects = await _tenantService.GetProspectiveTenantsAsync(queryParams);
                return Ok(prospects);
            }
            catch (Exception ex)
            {
                return BadRequest($"Error retrieving prospective tenants: {ex.Message}");
            }
        }

        /// <summary>
        /// Get preferences for a specific tenant
        /// Useful for understanding tenant requirements and matching properties
        /// </summary>
        /// <param name="tenantId">ID of the tenant</param>
        /// <returns>Tenant preference details</returns>
        [HttpGet("preferences/{tenantId}")]
        [Authorize]
        public async Task<ActionResult<TenantPreferenceResponse>> GetTenantPreferences(int tenantId)
        {
            try
            {
                var preferences = await _tenantService.GetTenantPreferencesAsync(tenantId);
                return Ok(preferences);
            }
            catch (UnauthorizedAccessException)
            {
                return Forbid("You don't have permission to access these tenant preferences");
            }
            catch (Exception ex)
            {
                return BadRequest($"Error retrieving tenant preferences: {ex.Message}");
            }
        }

        /// <summary>
        /// Update preferences for a specific tenant
        /// Allows modification of tenant search criteria and requirements
        /// </summary>
        /// <param name="tenantId">ID of the tenant</param>
        /// <param name="request">Updated tenant preference data</param>
        /// <returns>Updated tenant preference information</returns>
        [HttpPut("preferences/{tenantId}")]
        [Authorize]
        public async Task<ActionResult<TenantPreferenceResponse>> UpdateTenantPreferences(int tenantId, [FromBody] TenantPreferenceUpdateRequest request)
        {
            try
            {
                var updatedPreferences = await _tenantService.UpdateTenantPreferencesAsync(tenantId, request);
                return Ok(updatedPreferences);
            }
            catch (UnauthorizedAccessException)
            {
                return Forbid("You can only update your own tenant preferences");
            }
            catch (Exception ex)
            {
                return BadRequest($"Error updating tenant preferences: {ex.Message}");
            }
        }

        /// <summary>
        /// Get feedback/reviews for a specific tenant
        /// Returns tenant reviews created by the current landlord
        /// </summary>
        /// <param name="tenantId">ID of the tenant</param>
        /// <returns>List of reviews for the tenant</returns>
        [HttpGet("feedback/{tenantId}")]
        [Authorize(Roles = "Landlord")]
        public async Task<ActionResult<List<ReviewResponse>>> GetTenantFeedbacks(int tenantId)
        {
            try
            {
                var feedbacks = await _tenantService.GetTenantFeedbacksAsync(tenantId);
                return Ok(feedbacks);
            }
            catch (UnauthorizedAccessException)
            {
                return Forbid("You can only view feedback for tenants you have worked with");
            }
            catch (Exception ex)
            {
                return BadRequest($"Error retrieving tenant feedback: {ex.Message}");
            }
        }

        /// <summary>
        /// Add feedback/review for a tenant
        /// Validates landlord has business relationship with tenant before allowing review
        /// </summary>
        /// <param name="tenantId">ID of the tenant</param>
        /// <param name="request">Review data including rating and comments</param>
        /// <returns>Created review information</returns>
        [HttpPost("feedback/{tenantId}")]
        [Authorize(Roles = "Landlord")]
        public async Task<ActionResult<ReviewResponse>> AddTenantFeedback(int tenantId, [FromBody] ReviewInsertRequest request)
        {
            try
            {
                var feedback = await _tenantService.AddTenantFeedbackAsync(tenantId, request);
                return Ok(feedback);
            }
            catch (UnauthorizedAccessException)
            {
                return Forbid("You can only review tenants you have had business relationships with");
            }
            catch (ArgumentException ex)
            {
                return BadRequest($"Invalid review data: {ex.Message}");
            }
            catch (Exception ex)
            {
                return BadRequest($"Error adding tenant feedback: {ex.Message}");
            }
        }

        /// <summary>
        /// Record that a property was offered to a prospective tenant
        /// Tracks landlord outreach and property marketing efforts
        /// </summary>
        /// <param name="tenantId">ID of the tenant</param>
        /// <param name="propertyId">ID of the property offered</param>
        /// <returns>Success confirmation</returns>
        [HttpPost("{tenantId}/offer/{propertyId}")]
        [Authorize(Roles = "Landlord")]
        public async Task<IActionResult> RecordPropertyOfferedToTenant(int tenantId, int propertyId)
        {
            try
            {
                await _tenantService.RecordPropertyOfferedToTenantAsync(tenantId, propertyId);
                return Ok(new { message = "Property offer recorded successfully" });
            }
            catch (UnauthorizedAccessException)
            {
                return Forbid("You can only offer your own properties");
            }
            catch (Exception ex)
            {
                return BadRequest($"Error recording property offer: {ex.Message}");
            }
        }

        /// <summary>
        /// Get comprehensive tenant relationships for landlord portfolio
        /// Provides complete overview of tenant performance and property assignments
        /// </summary>
        /// <returns>List of tenant relationships with performance metrics</returns>
        [HttpGet("relationships")]
        [Authorize(Roles = "Landlord")]
        public async Task<ActionResult<List<TenantRelationshipResponse>>> GetTenantRelationships()
        {
            try
            {
                var relationships = await _tenantService.GetTenantRelationshipsForLandlordAsync();
                return Ok(relationships);
            }
            catch (Exception ex)
            {
                return BadRequest($"Error retrieving tenant relationships: {ex.Message}");
            }
        }

        /// <summary>
        /// Get property assignments for specific tenants
        /// Maps tenants to their assigned properties for portfolio management
        /// </summary>
        /// <param name="tenantIds">List of tenant IDs to get assignments for</param>
        /// <returns>Dictionary mapping tenant IDs to property information</returns>
        [HttpGet("assignments")]
        [Authorize(Roles = "Landlord")]
        public async Task<ActionResult<Dictionary<int, PropertyResponse>>> GetTenantPropertyAssignments([FromQuery] List<int> tenantIds)
        {
            try
            {
                if (tenantIds == null || !tenantIds.Any())
                    return BadRequest("At least one tenant ID must be provided");

                var assignments = await _tenantService.GetTenantPropertyAssignmentsAsync(tenantIds);
                return Ok(assignments);
            }
            catch (Exception ex)
            {
                return BadRequest($"Error retrieving tenant property assignments: {ex.Message}");
            }
        }
    }
} 