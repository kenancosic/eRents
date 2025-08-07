using eRents.Features.LookupManagement.Interfaces;
using eRents.Features.LookupManagement.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace eRents.Features.LookupManagement.Controllers
{
    /// <summary>
    /// API controller for accessing lookup data from enums and entities
    /// </summary>
    [ApiController]
    [Route("api/[controller]")]
    [Produces("application/json")]
    [AllowAnonymous] // Lookup data is generally public
    public class LookupController : ControllerBase
    {
        private readonly ILookupService _lookupService;
        private readonly ILogger<LookupController> _logger;

        public LookupController(ILookupService lookupService, ILogger<LookupController> logger)
        {
            _lookupService = lookupService ?? throw new ArgumentNullException(nameof(lookupService));
            _logger = logger ?? throw new ArgumentNullException(nameof(logger));
        }

        /// <summary>
        /// Gets all available lookup types
        /// </summary>
        [HttpGet("types")]
        [ProducesResponseType(200, Type = typeof(List<string>))]
        [ProducesResponseType(500)]
        public async Task<ActionResult<List<string>>> GetAvailableLookupTypes()
        {
            try
            {
                _logger.LogInformation("Getting available lookup types");
                var types = await _lookupService.GetAvailableLookupTypesAsync();
                return Ok(types);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting available lookup types");
                return StatusCode(500, "An error occurred while processing your request.");
            }
        }

        /// <summary>
        /// Gets booking status lookup items
        /// </summary>
        [HttpGet("booking-statuses")]
        [ProducesResponseType(200, Type = typeof(List<LookupItemResponse>))]
        [ProducesResponseType(500)]
        public async Task<ActionResult<List<LookupItemResponse>>> GetBookingStatuses()
        {
            try
            {
                _logger.LogInformation("Getting booking status lookup items");
                var items = await _lookupService.GetBookingStatusesAsync();
                return Ok(items);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting booking status lookup items");
                return StatusCode(500, "An error occurred while processing your request.");
            }
        }

        /// <summary>
        /// Gets property type lookup items
        /// </summary>
        [HttpGet("property-types")]
        [ProducesResponseType(200, Type = typeof(List<LookupItemResponse>))]
        [ProducesResponseType(500)]
        public async Task<ActionResult<List<LookupItemResponse>>> GetPropertyTypes()
        {
            try
            {
                _logger.LogInformation("Getting property type lookup items");
                var items = await _lookupService.GetPropertyTypesAsync();
                return Ok(items);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting property type lookup items");
                return StatusCode(500, "An error occurred while processing your request.");
            }
        }

        /// <summary>
        /// Gets rental type lookup items
        /// </summary>
        [HttpGet("rental-types")]
        [ProducesResponseType(200, Type = typeof(List<LookupItemResponse>))]
        [ProducesResponseType(500)]
        public async Task<ActionResult<List<LookupItemResponse>>> GetRentalTypes()
        {
            try
            {
                _logger.LogInformation("Getting rental type lookup items");
                var items = await _lookupService.GetRentalTypesAsync();
                return Ok(items);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting rental type lookup items");
                return StatusCode(500, "An error occurred while processing your request.");
            }
        }

        /// <summary>
        /// Gets user type lookup items
        /// </summary>
        [HttpGet("user-types")]
        [ProducesResponseType(200, Type = typeof(List<LookupItemResponse>))]
        [ProducesResponseType(500)]
        public async Task<ActionResult<List<LookupItemResponse>>> GetUserTypes()
        {
            try
            {
                _logger.LogInformation("Getting user type lookup items");
                var items = await _lookupService.GetUserTypesAsync();
                return Ok(items);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting user type lookup items");
                return StatusCode(500, "An error occurred while processing your request.");
            }
        }

        /// <summary>
        /// Gets property status lookup items
        /// </summary>
        [HttpGet("property-statuses")]
        [ProducesResponseType(200, Type = typeof(List<LookupItemResponse>))]
        [ProducesResponseType(500)]
        public async Task<ActionResult<List<LookupItemResponse>>> GetPropertyStatuses()
        {
            try
            {
                _logger.LogInformation("Getting property status lookup items");
                var items = await _lookupService.GetPropertyStatusesAsync();
                return Ok(items);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting property status lookup items");
                return StatusCode(500, "An error occurred while processing your request.");
            }
        }

        /// <summary>
        /// Gets maintenance issue priority lookup items
        /// </summary>
        [HttpGet("maintenance-issue-priorities")]
        [ProducesResponseType(200, Type = typeof(List<LookupItemResponse>))]
        [ProducesResponseType(500)]
        public async Task<ActionResult<List<LookupItemResponse>>> GetMaintenanceIssuePriorities()
        {
            try
            {
                _logger.LogInformation("Getting maintenance issue priority lookup items");
                var items = await _lookupService.GetMaintenanceIssuePrioritiesAsync();
                return Ok(items);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting maintenance issue priority lookup items");
                return StatusCode(500, "An error occurred while processing your request.");
            }
        }

        /// <summary>
        /// Gets maintenance issue status lookup items
        /// </summary>
        [HttpGet("maintenance-issue-statuses")]
        [ProducesResponseType(200, Type = typeof(List<LookupItemResponse>))]
        [ProducesResponseType(500)]
        public async Task<ActionResult<List<LookupItemResponse>>> GetMaintenanceIssueStatuses()
        {
            try
            {
                _logger.LogInformation("Getting maintenance issue status lookup items");
                var items = await _lookupService.GetMaintenanceIssueStatusesAsync();
                return Ok(items);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting maintenance issue status lookup items");
                return StatusCode(500, "An error occurred while processing your request.");
            }
        }

        /// <summary>
        /// Gets tenant status lookup items
        /// </summary>
        [HttpGet("tenant-statuses")]
        [ProducesResponseType(200, Type = typeof(List<LookupItemResponse>))]
        [ProducesResponseType(500)]
        public async Task<ActionResult<List<LookupItemResponse>>> GetTenantStatuses()
        {
            try
            {
                _logger.LogInformation("Getting tenant status lookup items");
                var items = await _lookupService.GetTenantStatusesAsync();
                return Ok(items);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting tenant status lookup items");
                return StatusCode(500, "An error occurred while processing your request.");
            }
        }

        /// <summary>
        /// Gets review type lookup items
        /// </summary>
        [HttpGet("review-types")]
        [ProducesResponseType(200, Type = typeof(List<LookupItemResponse>))]
        [ProducesResponseType(500)]
        public async Task<ActionResult<List<LookupItemResponse>>> GetReviewTypes()
        {
            try
            {
                _logger.LogInformation("Getting review type lookup items");
                var items = await _lookupService.GetReviewTypesAsync();
                return Ok(items);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting review type lookup items");
                return StatusCode(500, "An error occurred while processing your request.");
            }
        }

        /// <summary>
        /// Gets amenity lookup items (simplified list for dropdowns)
        /// </summary>
        [HttpGet("amenities")]
        [ProducesResponseType(200, Type = typeof(List<LookupItemResponse>))]
        [ProducesResponseType(500)]
        public async Task<ActionResult<List<LookupItemResponse>>> GetAmenities()
        {
            try
            {
                _logger.LogInformation("Getting amenity lookup items");
                var items = await _lookupService.GetAmenitiesAsync();
                return Ok(items);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting amenity lookup items");
                return StatusCode(500, "An error occurred while processing your request.");
            }
        }
    }
}