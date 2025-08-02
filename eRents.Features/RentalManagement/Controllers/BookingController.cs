using eRents.Features.RentalManagement.DTOs;
using eRents.Features.RentalManagement.Services;
using eRents.Features.Shared.Controllers;
using eRents.Features.Shared.DTOs;
using eRents.Features.Shared.Extensions;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;

namespace eRents.Features.RentalManagement.Controllers
{
	[ApiController]
	[Route("api/[controller]")]
	[Authorize]
	public class BookingController : BaseController
	{
		private readonly IRentalService _rentalService;
		private readonly ILogger<BookingController> _logger;

		public BookingController(IRentalService rentalService, ILogger<BookingController> logger) : base()
		{
			_rentalService = rentalService;
			_logger = logger;
		}

		/// <summary>
		/// Get paged bookings with optional search and sorting
		/// </summary>
		[HttpGet]
		public async Task<ActionResult<PagedResponse<BookingResponse>>> GetBookings([FromQuery] BookingSearchObject search)
		{
			return await this.GetPagedAsync<BookingResponse, BookingSearchObject>(
					search,
					_rentalService.GetBookingsAsync,
					_logger);
		}

		/// <summary>
		/// Get booking by ID
		/// </summary>
		[HttpGet("{id}")]
		public async Task<ActionResult<BookingResponse>> GetBooking(int id)
		{
			return await this.GetByIdAsync<BookingResponse, int>(
					id,
					_rentalService.GetBookingByIdAsync,
					_logger);
		}

		/// <summary>
		/// Create a new booking
		/// </summary>
		[HttpPost]
		[Authorize(Roles = "User,Tenant")]
		public async Task<ActionResult<BookingResponse>> CreateBooking([FromBody] BookingRequest request)
		{
			return await this.CreateAsync<BookingRequest, BookingResponse>(
					request,
					_rentalService.CreateBookingAsync,
					_logger,
					nameof(GetBooking));
		}

		/// <summary>
		/// Update an existing booking
		/// </summary>
		[HttpPut("{id}")]
		[Authorize(Roles = "User,Tenant,Landlord")]
		public async Task<ActionResult<BookingResponse>> UpdateBooking(int id, [FromBody] BookingUpdateRequest request)
		{
			return await this.UpdateAsync<BookingUpdateRequest, BookingResponse>(
					id,
					request,
					_rentalService.UpdateBookingAsync,
					_logger);
		}

		/// <summary>
		/// Cancel booking
		/// </summary>
		[HttpPost("{id}/cancel")]
		[Authorize(Roles = "User,Tenant,Landlord")]
		public async Task<ActionResult<BookingResponse>> CancelBooking(int id, [FromBody] BookingCancellationRequest request)
		{
			return await this.ExecuteAsync(() =>
			{
				request.BookingId = id; // Ensure consistency
				return _rentalService.CancelBookingAsync(request);
			}, _logger, $"CancelBooking({id})");
		}

		/// <summary>
		/// Delete booking (hard delete)
		/// </summary>
		[HttpDelete("{id}")]
		[Authorize(Roles = "User,Tenant,Landlord")]
		public async Task<ActionResult> DeleteBooking(int id)
		{
			return await this.DeleteAsync(
					id,
					_rentalService.DeleteBookingAsync,
					_logger);
		}

		/// <summary>
		/// Check property availability
		/// </summary>
		[HttpGet("availability/{propertyId}")]
		[AllowAnonymous]
		public async Task<ActionResult<object>> CheckAvailability(int propertyId, [FromQuery] DateTime startDate, [FromQuery] DateTime endDate)
		{
			return await this.ExecuteAsync(() => 
				_rentalService.CheckPropertyAvailabilityAsync(propertyId, startDate, endDate),
				_logger, $"CheckAvailability({propertyId}, {startDate:yyyy-MM-dd}, {endDate:yyyy-MM-dd})");
		}

		/// <summary>
		/// Simple availability check (returns boolean)
		/// </summary>
		[HttpGet("availability/{propertyId}/simple")]
		[AllowAnonymous]
		public async Task<IActionResult> CheckSimpleAvailability(int propertyId, [FromQuery] DateTime startDate, [FromQuery] DateTime endDate)
		{
			try
			{
				var isAvailable = await _rentalService.IsPropertyAvailableAsync(
						propertyId, startDate, endDate);

				return Ok(SuccessResponse(new
				{
					IsAvailable = isAvailable,
					PropertyId = propertyId,
					StartDate = startDate,
					EndDate = endDate
				}, "Availability check successful"));
			}
			catch (Exception ex)
			{
				return StatusCode(500, ErrorResponse($"An error occurred while checking availability: {ex.Message}"));
			}
		}

		/// <summary>
		/// Get current active stays for current user
		/// </summary>
		[HttpGet("current")]
		public async Task<IActionResult> GetCurrentStays([FromQuery] int? propertyId = null)
		{
			try
			{
				var result = await _rentalService.GetCurrentStaysAsync();

				// Filter by property if specified (for landlord property details)
				if (propertyId.HasValue)
				{
					result = result.Where(b => b.PropertyId == propertyId.Value).ToList();
				}

				return Ok(SuccessResponse(result, "Current stays retrieved successfully"));
			}
			catch (Exception ex)
			{
				return StatusCode(500, ErrorResponse($"An error occurred while retrieving current stays: {ex.Message}"));
			}
		}

		/// <summary>
		/// Get upcoming stays for current user
		/// </summary>
		[HttpGet("upcoming")]
		public async Task<IActionResult> GetUpcomingStays([FromQuery] int? propertyId = null)
		{
			try
			{
				var result = await _rentalService.GetUpcomingStaysAsync();

				// Filter by property if specified (for landlord property details)
				if (propertyId.HasValue)
				{
					result = result.Where(b => b.PropertyId == propertyId.Value).ToList();
				}

				return Ok(SuccessResponse(result, "Upcoming stays retrieved successfully"));
			}
			catch (Exception ex)
			{
				return StatusCode(500, ErrorResponse($"An error occurred while retrieving upcoming stays: {ex.Message}"));
			}
		}

		/// <summary>
		/// Calculate refund amount for booking cancellation
		/// </summary>
		[HttpGet("{id}/refund-calculation")]
		[Authorize(Roles = "User,Tenant,Landlord")]
		public async Task<IActionResult> CalculateRefundAmount(int id, [FromQuery] DateTime? cancellationDate = null)
		{
			try
			{
				var refundAmount = await _rentalService.CalculateRefundAmountAsync(id, cancellationDate);

				return Ok(SuccessResponse(new
				{
					BookingId = id,
					RefundAmount = refundAmount,
					CancellationDate = cancellationDate ?? DateTime.UtcNow
				}, "Refund amount calculated successfully"));
			}
			catch (Exception ex)
			{
				return StatusCode(500, ErrorResponse($"An error occurred while calculating refund amount: {ex.Message}"));
			}
		}

		/// <summary>
		/// Get current user's bookings
		/// </summary>
		[HttpGet("my-bookings")]
		public async Task<IActionResult> GetMyBookings()
		{
			try
			{
				var result = await _rentalService.GetCurrentUserBookingsAsync();
				return Ok(SuccessResponse(result, "Your bookings retrieved successfully"));
			}
			catch (Exception ex)
			{
				return StatusCode(500, ErrorResponse($"An error occurred while retrieving your bookings: {ex.Message}"));
			}
		}

		// Rental Request Endpoints
		/// <summary>
		/// Get rental request by ID
		/// </summary>
		[HttpGet("requests/{id}")]
		public async Task<ActionResult<RentalRequestResponse>> GetRentalRequest(int id)
		{
			return await this.GetByIdAsync<RentalRequestResponse, int>(
					id,
					_rentalService.GetRentalRequestByIdAsync,
					_logger);
		}

		/// <summary>
		/// Create a new rental request
		/// </summary>
		[HttpPost("requests")]
		[Authorize(Roles = "User,Tenant")]
		public async Task<ActionResult<RentalRequestResponse>> CreateRentalRequest([FromBody] RentalRequestRequest request)
		{
			return await this.CreateAsync<RentalRequestRequest, RentalRequestResponse>(
					request,
					_rentalService.CreateRentalRequestAsync,
					_logger,
					nameof(GetRentalRequest));
		}

		/// <summary>
		/// Update an existing rental request
		/// </summary>
		[HttpPut("requests/{id}")]
		[Authorize(Roles = "User,Tenant,Landlord")]
		public async Task<ActionResult<RentalRequestResponse>> UpdateRentalRequest(int id, [FromBody] RentalRequestRequest request)
		{
			return await this.UpdateAsync<RentalRequestRequest, RentalRequestResponse>(
					id,
					request,
					_rentalService.UpdateRentalRequestAsync,
					_logger);
		}

		/// <summary>
		/// Delete rental request
		/// </summary>
		[HttpDelete("requests/{id}")]
		[Authorize(Roles = "User,Tenant,Landlord")]
		public async Task<ActionResult> DeleteRentalRequest(int id)
		{
			return await this.DeleteAsync(
					id,
					_rentalService.DeleteRentalRequestAsync,
					_logger);
		}

		/// <summary>
		/// Get paged rental requests with optional search and sorting
		/// </summary>
		[HttpGet("requests")]
		public async Task<ActionResult<PagedResponse<RentalRequestResponse>>> GetRentalRequests([FromQuery] RentalFilterRequest filter)
		{
			return await this.GetPagedAsync<RentalRequestResponse, RentalFilterRequest>(
					filter,
					_rentalService.GetRentalRequestsAsync,
					_logger);
		}

		/// <summary>
		/// Get rental requests for specific property
		/// </summary>
		[HttpGet("requests/property/{propertyId}")]
		public async Task<ActionResult<List<RentalRequestResponse>>> GetPropertyRentalRequests(int propertyId)
		{
			return await this.ExecuteAsync(() =>
					_rentalService.GetPropertyRentalRequestsAsync(propertyId),
					_logger, $"GetPropertyRentalRequests({propertyId})");
		}

		/// <summary>
		/// Get pending rental requests requiring action
		/// </summary>
		[HttpGet("requests/pending")]
		public async Task<ActionResult<List<RentalRequestResponse>>> GetPendingRentalRequests()
		{
			return await this.ExecuteAsync(() =>
					_rentalService.GetPendingRentalRequestsAsync(),
					_logger, "GetPendingRentalRequests");
		}

		/// <summary>
		/// Get expired rental requests
		/// </summary>
		[HttpGet("requests/expired")]
		public async Task<ActionResult<List<RentalRequestResponse>>> GetExpiredRentalRequests()
		{
			return await this.ExecuteAsync(() =>
					_rentalService.GetExpiredRentalRequestsAsync(),
					_logger, "GetExpiredRentalRequests");
		}

		/// <summary>
		/// Approve rental request
		/// </summary>
		[HttpPost("requests/{id}/approve")]
		[Authorize(Roles = "Landlord")]
		public async Task<ActionResult<RentalRequestResponse>> ApproveRentalRequest(int id, [FromBody] RentalApprovalRequest request)
		{
			return await this.ExecuteAsync(() =>
			{
				return _rentalService.ApproveRentalRequestAsync(id, request);
			}, _logger, $"ApproveRentalRequest({id})");
		}

		/// <summary>
		/// Reject rental request
		/// </summary>
		[HttpPost("requests/{id}/reject")]
		[Authorize(Roles = "Landlord")]
		public async Task<ActionResult<RentalRequestResponse>> RejectRentalRequest(int id, [FromBody] RentalApprovalRequest request)
		{
			return await this.ExecuteAsync(() =>
			{
				return _rentalService.RejectRentalRequestAsync(id, request);
			}, _logger, $"RejectRentalRequest({id})");
		}

		/// <summary>
		/// Cancel rental request
		/// </summary>
		[HttpPost("requests/{id}/cancel-request")]
		[Authorize(Roles = "User,Tenant")]
		public async Task<ActionResult<RentalRequestResponse>> CancelRentalRequest(int id, [FromQuery] string? reason = null)
		{
			return await this.ExecuteAsync(() =>
			{
				return _rentalService.CancelRentalRequestAsync(id, reason);
			}, _logger, $"CancelRentalRequest({id})");
		}
	}
}