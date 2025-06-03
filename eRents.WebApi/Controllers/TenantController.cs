using eRents.Application.Service.TenantService;
using eRents.Application.Service.UserService;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Shared.Services;
using eRents.WebApi.Controllers.Base;
using eRents.Shared.SearchObjects;
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
    public class TenantController : EnhancedBaseCRUDController<UserResponse, UserSearchObject, UserInsertRequest, UserUpdateRequest>
    {
        private readonly ITenantService _tenantService;

        public TenantController(
            ITenantService tenantService, 
            ICurrentUserService currentUserService,
            ILogger<TenantController> logger,
            IUserService userService) : base(userService, logger, currentUserService)
        {
            _tenantService = tenantService;
        }

        /// <summary>
        /// Get current tenants for the authenticated landlord
        /// Returns tenants who have active bookings in landlord's properties
        /// </summary>
        /// <param name="queryParams">Optional filtering and search parameters</param>
        /// <returns>List of current tenants with user details</returns>
        [HttpGet("current")]
        [Authorize(Roles = "Landlord")]
        public async Task<IActionResult> GetCurrentTenants([FromQuery] Dictionary<string, string>? queryParams = null)
        {
            try
            {
                var tenants = await _tenantService.GetCurrentTenantsAsync(queryParams);
                
                _logger.LogInformation("Landlord {UserId} retrieved {TenantCount} current tenants", 
                    _currentUserService.UserId ?? "unknown", tenants.Count);
                    
                return Ok(tenants);
            }
            catch (Exception ex)
            {
                return HandleStandardError(ex, "Current tenants retrieval");
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
        public async Task<IActionResult> GetTenantById(int tenantId)
        {
            try
            {
                var tenant = await _tenantService.GetTenantByIdAsync(tenantId);
                if (tenant == null)
                {
                    _logger.LogWarning("Tenant {TenantId} not found for landlord {LandlordId}", 
                        tenantId, _currentUserService.UserId ?? "unknown");
                    return NotFound("Tenant not found");
                }

                _logger.LogInformation("Landlord {LandlordId} retrieved tenant details for {TenantId}", 
                    _currentUserService.UserId ?? "unknown", tenantId);
                    
                return Ok(tenant);
            }
            catch (Exception ex)
            {
                return HandleStandardError(ex, $"Tenant details retrieval (ID: {tenantId})");
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
        public async Task<IActionResult> GetProspectiveTenants([FromQuery] Dictionary<string, string>? queryParams = null)
        {
            try
            {
                var prospects = await _tenantService.GetProspectiveTenantsAsync(queryParams);
                
                _logger.LogInformation("Landlord {LandlordId} retrieved {ProspectCount} prospective tenants", 
                    _currentUserService.UserId ?? "unknown", prospects.Count);
                    
                return Ok(prospects);
            }
            catch (Exception ex)
            {
                return HandleStandardError(ex, "Prospective tenants retrieval");
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
        public async Task<IActionResult> GetTenantPreferences(int tenantId)
        {
            try
            {
                var preferences = await _tenantService.GetTenantPreferencesAsync(tenantId);
                
                _logger.LogInformation("User {UserId} retrieved preferences for tenant {TenantId}", 
                    _currentUserService.UserId ?? "unknown", tenantId);
                    
                return Ok(preferences);
            }
            catch (Exception ex)
            {
                return HandleStandardError(ex, $"Tenant preferences retrieval (ID: {tenantId})");
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
        public async Task<IActionResult> UpdateTenantPreferences(int tenantId, [FromBody] TenantPreferenceUpdateRequest request)
        {
            try
            {
                var updatedPreferences = await _tenantService.UpdateTenantPreferencesAsync(tenantId, request);
                
                _logger.LogInformation("User {UserId} updated preferences for tenant {TenantId}", 
                    _currentUserService.UserId ?? "unknown", tenantId);
                    
                return Ok(updatedPreferences);
            }
            catch (Exception ex)
            {
                return HandleStandardError(ex, $"Tenant preferences update (ID: {tenantId})");
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
        public async Task<IActionResult> GetTenantFeedbacks(int tenantId)
        {
            try
            {
                var feedbacks = await _tenantService.GetTenantFeedbacksAsync(tenantId);
                
                _logger.LogInformation("Landlord {LandlordId} retrieved {FeedbackCount} feedbacks for tenant {TenantId}", 
                    _currentUserService.UserId ?? "unknown", feedbacks.Count, tenantId);
                    
                return Ok(feedbacks);
            }
            catch (Exception ex)
            {
                return HandleStandardError(ex, $"Tenant feedbacks retrieval (ID: {tenantId})");
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
        public async Task<IActionResult> AddTenantFeedback(int tenantId, [FromBody] ReviewInsertRequest request)
        {
            try
            {
                var feedback = await _tenantService.AddTenantFeedbackAsync(tenantId, request);
                
                _logger.LogInformation("Landlord {LandlordId} added feedback for tenant {TenantId}", 
                    _currentUserService.UserId ?? "unknown", tenantId);
                    
                return Ok(feedback);
            }
            catch (Exception ex)
            {
                return HandleStandardError(ex, $"Tenant feedback creation (ID: {tenantId})");
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
                
                _logger.LogInformation("Landlord {LandlordId} offered property {PropertyId} to tenant {TenantId}", 
                    _currentUserService.UserId ?? "unknown", propertyId, tenantId);
                    
                return Ok(new { message = "Property offer recorded successfully" });
            }
            catch (Exception ex)
            {
                return HandleStandardError(ex, $"Property offer recording (TenantID: {tenantId}, PropertyID: {propertyId})");
            }
        }

        /// <summary>
        /// Get comprehensive tenant relationships for landlord portfolio
        /// Provides complete overview of tenant performance and property assignments
        /// </summary>
        /// <returns>List of tenant relationships with performance metrics</returns>
        [HttpGet("relationships")]
        [Authorize(Roles = "Landlord")]
        public async Task<IActionResult> GetTenantRelationships()
        {
            try
            {
                var relationships = await _tenantService.GetTenantRelationshipsForLandlordAsync();
                
                _logger.LogInformation("Landlord {LandlordId} retrieved {RelationshipCount} tenant relationships", 
                    _currentUserService.UserId ?? "unknown", relationships.Count);
                    
                return Ok(relationships);
            }
            catch (Exception ex)
            {
                return HandleStandardError(ex, "Tenant relationships retrieval");
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
        public async Task<IActionResult> GetTenantPropertyAssignments([FromQuery] List<int> tenantIds)
        {
            try
            {
                if (tenantIds == null || !tenantIds.Any())
                {
                    _logger.LogWarning("Tenant property assignments request failed - No tenant IDs provided by landlord {LandlordId}", 
                        _currentUserService.UserId ?? "unknown");
                    return BadRequest("At least one tenant ID must be provided");
                }

                var assignments = await _tenantService.GetTenantPropertyAssignmentsAsync(tenantIds);
                
                _logger.LogInformation("Landlord {LandlordId} retrieved property assignments for {TenantCount} tenants", 
                    _currentUserService.UserId ?? "unknown", tenantIds.Count);
                    
                return Ok(assignments);
            }
            catch (Exception ex)
            {
                return HandleStandardError(ex, $"Tenant property assignments retrieval ({tenantIds?.Count ?? 0} tenants)");
            }
        }
    }
} 