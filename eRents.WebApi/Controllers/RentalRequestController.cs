using eRents.Application.Services.RentalRequestService;
using eRents.Application.Services.RentalCoordinatorService;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Shared.SearchObjects;
using eRents.Shared.Services;
using eRents.WebApi.Controllers.Base;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Text.Json;

namespace eRents.WebApi.Controllers
{
    /// <summary>
    /// Controller for managing annual rental requests in the dual rental system
    /// ✅ Phase 3: Migrated to use IRentalCoordinatorService for clean architecture
    /// </summary>
    [ApiController]
    [Route("[controller]")]
    [Authorize]
    public class RentalRequestController : BaseCRUDController<RentalRequestResponse, RentalRequestSearchObject, RentalRequestInsertRequest, RentalRequestUpdateRequest>
    {
        private readonly IRentalRequestService _rentalRequestService;
        private readonly IRentalCoordinatorService _rentalCoordinatorService;
        private readonly ICurrentUserService _currentUserService;

        public RentalRequestController(
            IRentalRequestService rentalRequestService, 
            IRentalCoordinatorService rentalCoordinatorService,
            ILogger<RentalRequestController> logger,
            ICurrentUserService currentUserService) 
            : base(rentalRequestService, logger, currentUserService)
        {
            _rentalRequestService = rentalRequestService;
            _rentalCoordinatorService = rentalCoordinatorService;
            _currentUserService = currentUserService;
        }

        /// <summary>
        /// Request an annual rental for a property (Phase 2 endpoint)
        /// </summary>
        [HttpPost("request-annual-rental")]
        [Authorize]
        public async Task<IActionResult> RequestAnnualRental([FromBody] RentalRequestInsertRequest request)
        {
            try
            {
                var result = await _rentalRequestService.RequestAnnualRentalAsync(request);
                return Ok(result);
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "An unexpected error occurred", details = ex.Message });
            }
        }

        /// <summary>
        /// Approve or reject a rental request (Phase 2 endpoint)
        /// </summary>
        [HttpPost("approve/{requestId}")]
        [Authorize(Roles = "Landlord")]
        public async Task<IActionResult> ApproveRequest(int requestId, [FromBody] JsonElement responsePayload)
        {
            string? response = responsePayload.TryGetProperty("response", out var r) ? r.GetString() : "Request approved.";
            try
            {
                var result = await _rentalRequestService.ApproveRequestAsync(requestId, response);
                return Ok(result);
            }
            catch (UnauthorizedAccessException ex)
            {
                return Forbid(ex.Message);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "An unexpected error occurred", details = ex.Message });
            }
        }

        /// <summary>
        /// Reject a rental request (Phase 2 endpoint)
        /// </summary>
        [HttpPost("reject/{requestId}")]
        [Authorize(Roles = "Landlord")]
        public async Task<IActionResult> RejectRequest(int requestId, [FromBody] JsonElement responsePayload)
        {
            string? response = responsePayload.TryGetProperty("response", out var r) ? r.GetString() : "Request rejected.";
            try
            {
                var result = await _rentalRequestService.RejectRequestAsync(requestId, response);
                return Ok(result);
            }
            catch (UnauthorizedAccessException ex)
            {
                return Forbid(ex.Message);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "An unexpected error occurred", details = ex.Message });
            }
        }

        /// <summary>
        /// Get pending rental requests for current landlord (Phase 2 endpoint)
        /// </summary>
        [HttpGet("pending-requests")]
        [Authorize(Roles = "Landlord")]
        public async Task<IActionResult> GetPendingRequests()
        {
            try
            {
                var result = await _rentalRequestService.GetPendingRequestsAsync();
                return Ok(result);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "An unexpected error occurred", details = ex.Message });
            }
        }

        /// <summary>
        /// Get all requests for current landlord's properties
        /// </summary>
        [HttpGet("my-property-requests")]
        public async Task<IActionResult> GetMyPropertyRequests()
        {
            try
            {
                var requests = await _rentalRequestService.GetAllRequestsForMyPropertiesAsync();
                return Ok(requests);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = "An error occurred while retrieving property requests." });
            }
        }

        /// <summary>
        /// Get current user's rental requests
        /// </summary>
        [HttpGet("my-requests")]
        [Authorize]
        public async Task<IActionResult> GetMyRequests()
        {
            try
            {
                var result = await _rentalRequestService.GetMyRequestsAsync();
                return Ok(result);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "An unexpected error occurred", details = ex.Message });
            }
        }

        /// <summary>
        /// Withdraw a pending rental request
        /// </summary>
        [HttpPost("withdraw/{requestId}")]
        public async Task<IActionResult> WithdrawRequest(int requestId)
        {
            try
            {
                var result = await _rentalRequestService.WithdrawRequestAsync(requestId);
                return Ok(result);
            }
            catch (UnauthorizedAccessException)
            {
                return Forbid();
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new { error = ex.Message });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = "An error occurred while withdrawing the request." });
            }
        }

        /// <summary>
        /// Check if current user can request a specific property
        /// </summary>
        [HttpGet("can-request/{propertyId}")]
        public async Task<IActionResult> CanRequestProperty(int propertyId)
        {
            try
            {
                var canRequest = await _rentalRequestService.CanRequestPropertyAsync(propertyId);
                return Ok(new { canRequest });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = "An error occurred while checking property availability." });
            }
        }

        /// <summary>
        /// Get expiring contracts (Phase 3 testing endpoint)
        /// </summary>
        [HttpGet("expiring-contracts")]
        public async Task<IActionResult> GetExpiringContracts([FromQuery] int daysAhead = 60)
        {
            try
            {
                var contracts = await _rentalCoordinatorService.GetExpiringContractsAsync(daysAhead);
                return Ok(contracts);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = "An error occurred while retrieving expiring contracts." });
            }
        }
    }
} 