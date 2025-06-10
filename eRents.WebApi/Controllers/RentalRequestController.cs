using eRents.Application.Service.RentalRequestService;
using eRents.Application.Service.SimpleRentalService;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Shared.SearchObjects;
using eRents.Shared.Services;
using eRents.WebApi.Controllers.Base;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace eRents.WebApi.Controllers
{
    /// <summary>
    /// Controller for managing annual rental requests in the dual rental system
    /// Implements Phase 2 rental request workflow with landlord approval process
    /// </summary>
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class RentalRequestController : BaseCRUDController<RentalRequestResponse, RentalRequestSearchObject, RentalRequestInsertRequest, RentalRequestUpdateRequest>
    {
        private readonly IRentalRequestService _rentalRequestService;
        private readonly ISimpleRentalService _simpleRentalService;

        public RentalRequestController(
            IRentalRequestService rentalRequestService, 
            ISimpleRentalService simpleRentalService,
            ILogger<RentalRequestController> logger,
            ICurrentUserService currentUserService) 
            : base(rentalRequestService, logger, currentUserService)
        {
            _rentalRequestService = rentalRequestService;
            _simpleRentalService = simpleRentalService;
        }

        /// <summary>
        /// Request an annual rental for a property (Phase 2 endpoint)
        /// </summary>
        [HttpPost("request-rental")]
        public async Task<IActionResult> RequestRental([FromBody] RentalRequestInsertRequest request)
        {
            try
            {
                var result = await _rentalRequestService.RequestAnnualRentalAsync(request);
                return Ok(result);
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new { error = ex.Message });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = "An error occurred while processing your rental request." });
            }
        }

        /// <summary>
        /// Approve or reject a rental request (Phase 2 endpoint)
        /// </summary>
        [HttpPost("approve-rental/{requestId}")]
        public async Task<IActionResult> ApproveRental(int requestId, [FromBody] ApprovalRequest request)
        {
            try
            {
                var result = await _simpleRentalService.ApproveRentalRequestAsync(requestId, request.Approved, request.Response);
                if (result)
                    return Ok(new { message = request.Approved ? "Request approved successfully" : "Request rejected successfully" });
                else
                    return BadRequest(new { error = "Failed to process approval" });
            }
            catch (UnauthorizedAccessException)
            {
                return Forbid();
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = "An error occurred while processing the approval." });
            }
        }

        /// <summary>
        /// Get pending rental requests for current landlord (Phase 2 endpoint)
        /// </summary>
        [HttpGet("pending-requests")]
        public async Task<IActionResult> GetPendingRequests()
        {
            try
            {
                var requests = await _rentalRequestService.GetPendingRequestsAsync();
                return Ok(requests);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = "An error occurred while retrieving pending requests." });
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
        public async Task<IActionResult> GetMyRequests()
        {
            try
            {
                var requests = await _rentalRequestService.GetMyRequestsAsync();
                return Ok(requests);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = "An error occurred while retrieving your requests." });
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
                var contracts = await _simpleRentalService.GetExpiringContractsAsync(daysAhead);
                return Ok(contracts);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = "An error occurred while retrieving expiring contracts." });
            }
        }
    }

    /// <summary>
    /// Request DTO for rental approval/rejection
    /// </summary>
    public class ApprovalRequest
    {
        public bool Approved { get; set; }
        public string? Response { get; set; }
    }
} 