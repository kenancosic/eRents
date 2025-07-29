using eRents.Features.BookingManagement.DTOs;
using eRents.Features.BookingManagement.Services;
using eRents.Features.Shared.Controllers;
using eRents.Features.Shared.DTOs;
using eRents.Features.Shared.Extensions;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;

namespace eRents.Features.BookingManagement.Controllers
{
	[ApiController]
	[Route("api/[controller]")]
	[Authorize]
	public class BookingController : BaseController
	{
		private readonly IBookingService _bookingService;
		private readonly ILogger<BookingController> _logger;

		public BookingController(IBookingService bookingService, ILogger<BookingController> logger) : base()
		{
			_bookingService = bookingService;
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
					_bookingService.GetBookingsAsync,
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
					_bookingService.GetBookingByIdAsync,
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
					_bookingService.CreateBookingAsync,
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
					_bookingService.UpdateBookingAsync,
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
				return _bookingService.CancelBookingAsync(request);
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
					_bookingService.DeleteBookingAsync,
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
				_bookingService.CheckPropertyAvailabilityAsync(propertyId, startDate, endDate),
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
				var isAvailable = await _bookingService.IsPropertyAvailableAsync(
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
				var result = await _bookingService.GetCurrentStaysAsync();

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
				var result = await _bookingService.GetUpcomingStaysAsync();

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
				var refundAmount = await _bookingService.CalculateRefundAmountAsync(id, cancellationDate);

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
				var result = await _bookingService.GetCurrentUserBookingsAsync();
				return Ok(SuccessResponse(result, "Your bookings retrieved successfully"));
			}
			catch (Exception ex)
			{
				return StatusCode(500, ErrorResponse($"An error occurred while retrieving your bookings: {ex.Message}"));
			}
		}
	}
}
