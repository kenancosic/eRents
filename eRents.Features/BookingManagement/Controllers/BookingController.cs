using eRents.Domain.Shared.Interfaces;
using eRents.Features.BookingManagement.DTOs;
using eRents.Features.BookingManagement.Services;
using eRents.Features.PropertyManagement.DTOs;
using eRents.Features.Shared.DTOs;
using eRents.Features.Shared.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;

namespace eRents.Features.BookingManagement.Controllers;

/// <summary>
/// Bookings management controller using modular architecture
/// Clean separation with BookingManagement feature services and DTOs
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Authorize]
public class BookingController : ControllerBase
{
	private readonly IBookingService _bookingService;
	private readonly ICurrentUserService _currentUserService;
	private readonly ILogger<BookingController> _logger;

	public BookingController(
			IBookingService bookingService,
			ICurrentUserService currentUserService,
			ILogger<BookingController> logger)
	{
		_bookingService = bookingService;
		_currentUserService = currentUserService;
		_logger = logger;
	}

	/// <summary>
	/// Get paginated bookings with filtering and sorting
	/// </summary>
	[HttpGet]
	public async Task<ActionResult<PagedResponse<BookingResponse>>> GetBookings([FromQuery] BookingSearchObject search)
	{
		try
		{
			var result = await _bookingService.GetBookingsAsync(search);
			return Ok(result);
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error retrieving bookings for user {UserId}", _currentUserService.UserId);
			return StatusCode(500, new { error = "An error occurred while retrieving bookings" });
		}
	}

	/// <summary>
	/// Get booking by ID
	/// </summary>
	[HttpGet("{id}")]
	public async Task<ActionResult<BookingResponse>> GetBooking(int id)
	{
		try
		{
			var booking = await _bookingService.GetBookingByIdAsync(id);
			if (booking == null)
				return NotFound();

			return Ok(booking);
		}
		catch (UnauthorizedAccessException)
		{
			return Forbid();
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error retrieving booking {BookingId} for user {UserId}", id, _currentUserService.UserId);
			return StatusCode(500, new { error = "An error occurred while retrieving the booking" });
		}
	}

	/// <summary>
	/// Create new booking
	/// </summary>
	[HttpPost]
	[Authorize(Roles = "User,Tenant")]
	public async Task<ActionResult<BookingResponse>> CreateBooking([FromBody] BookingRequest request)
	{
		try
		{
			var result = await _bookingService.CreateBookingAsync(request);

			_logger.LogInformation("Booking created successfully: {BookingId} by user {UserId} for property {PropertyId}",
					result.BookingId, _currentUserService.UserId, request.PropertyId);

			return CreatedAtAction(nameof(GetBooking), new { id = result.BookingId }, result);
		}
		catch (ArgumentException ex)
		{
			return BadRequest(new { error = ex.Message });
		}
		catch (InvalidOperationException ex)
		{
			return Conflict(new { error = ex.Message });
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Booking creation failed for user {UserId} and property {PropertyId}",
					_currentUserService.UserId, request.PropertyId);
			return StatusCode(500, new { error = "An error occurred while creating the booking" });
		}
	}

	/// <summary>
	/// Update existing booking
	/// </summary>
	[HttpPut("{id}")]
	[Authorize(Roles = "User,Tenant,Landlord")]
	public async Task<ActionResult<BookingResponse>> UpdateBooking(int id, [FromBody] BookingUpdateRequest request)
	{
		try
		{
			var result = await _bookingService.UpdateBookingAsync(id, request);

			_logger.LogInformation("Booking updated successfully: {BookingId} by user {UserId}",
					id, _currentUserService.UserId);

			return Ok(result);
		}
		catch (ArgumentException ex)
		{
			return BadRequest(new { error = ex.Message });
		}
		catch (UnauthorizedAccessException)
		{
			return Forbid();
		}
		catch (KeyNotFoundException)
		{
			return NotFound();
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Booking update failed for user {UserId} and booking {BookingId}",
					_currentUserService.UserId, id);
			return StatusCode(500, new { error = "An error occurred while updating the booking" });
		}
	}

	/// <summary>
	/// Cancel booking
	/// </summary>
	[HttpPost("{id}/cancel")]
	[Authorize(Roles = "User,Tenant,Landlord")]
	public async Task<ActionResult<BookingResponse>> CancelBooking(int id, [FromBody] BookingCancellationRequest request)
	{
		try
		{
			request.BookingId = id; // Ensure consistency
			var result = await _bookingService.CancelBookingAsync(request);

			_logger.LogInformation("Booking cancelled successfully: {BookingId} by user {UserId}",
					id, _currentUserService.UserId);

			return Ok(result);
		}
		catch (ArgumentException ex)
		{
			return BadRequest(new { error = ex.Message });
		}
		catch (UnauthorizedAccessException)
		{
			return Forbid();
		}
		catch (KeyNotFoundException)
		{
			return NotFound();
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Booking cancellation failed for user {UserId} and booking {BookingId}",
					_currentUserService.UserId, id);
			return StatusCode(500, new { error = "An error occurred while cancelling the booking" });
		}
	}

	/// <summary>
	/// Delete booking (hard delete)
	/// </summary>
	[HttpDelete("{id}")]
	[Authorize(Roles = "User,Tenant,Landlord")]
	public async Task<ActionResult> DeleteBooking(int id)
	{
		try
		{
			var success = await _bookingService.DeleteBookingAsync(id);
			if (!success)
				return NotFound();

			_logger.LogInformation("Booking deleted successfully: {BookingId} by user {UserId}",
					id, _currentUserService.UserId);

			return NoContent();
		}
		catch (UnauthorizedAccessException)
		{
			return Forbid();
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Booking deletion failed for user {UserId} and booking {BookingId}",
					_currentUserService.UserId, id);
			return StatusCode(500, new { error = "An error occurred while deleting the booking" });
		}
	}

	/// <summary>
	/// Check property availability
	/// </summary>
	[HttpGet("availability/{propertyId}")]
	[AllowAnonymous]
	public async Task<ActionResult<PropertyAvailabilityResponse>> CheckAvailability(
			int propertyId, [FromQuery] DateTime startDate, [FromQuery] DateTime endDate)
	{
		try
		{
			var result = await _bookingService.CheckPropertyAvailabilityAsync(propertyId, startDate, endDate);

			_logger.LogInformation("Availability check for property {PropertyId} from {StartDate} to {EndDate}: {IsAvailable}",
					propertyId, startDate.ToShortDateString(), endDate.ToShortDateString(), result.IsAvailable);

			return Ok(result);
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Availability check failed for property {PropertyId}", propertyId);
			return StatusCode(500, new { error = "An error occurred while checking availability" });
		}
	}

	/// <summary>
	/// Simple availability check (returns boolean)
	/// </summary>
	[HttpGet("availability/{propertyId}/simple")]
	[AllowAnonymous]
	public async Task<ActionResult<object>> CheckSimpleAvailability(
			int propertyId, [FromQuery] DateTime startDate, [FromQuery] DateTime endDate)
	{
		try
		{
			var isAvailable = await _bookingService.IsPropertyAvailableAsync(
					propertyId, DateOnly.FromDateTime(startDate), DateOnly.FromDateTime(endDate));

			return Ok(new
			{
				IsAvailable = isAvailable,
				PropertyId = propertyId,
				StartDate = startDate,
				EndDate = endDate
			});
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Simple availability check failed for property {PropertyId}", propertyId);
			return StatusCode(500, new { error = "An error occurred while checking availability" });
		}
	}

	/// <summary>
	/// Get current active stays for current user
	/// </summary>
	[HttpGet("current")]
	public async Task<ActionResult<List<BookingResponse>>> GetCurrentStays([FromQuery] int? propertyId = null)
	{
		try
		{
			var userId = _currentUserService.GetUserIdAsInt();
			if (userId == 0)
				return Unauthorized();

			var result = await _bookingService.GetCurrentStaysAsync(userId.Value);

			// Filter by property if specified (for landlord property details)
			if (propertyId.HasValue)
			{
				result = result.Where(b => b.PropertyId == propertyId.Value).ToList();
				_logger.LogInformation("User {UserId} retrieved {StayCount} current stays for property {PropertyId}",
						userId, result.Count, propertyId.Value);
			}
			else
			{
				_logger.LogInformation("User {UserId} retrieved {StayCount} current stays",
						userId, result.Count);
			}

			return Ok(result);
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Current stays retrieval failed for user {UserId}", _currentUserService.UserId);
			return StatusCode(500, new { error = "An error occurred while retrieving current stays" });
		}
	}

	/// <summary>
	/// Get upcoming stays for current user
	/// </summary>
	[HttpGet("upcoming")]
	public async Task<ActionResult<List<BookingResponse>>> GetUpcomingStays([FromQuery] int? propertyId = null)
	{
		try
		{
			var userId = _currentUserService.GetUserIdAsInt();
			if (userId == 0)
				return Unauthorized();

			var result = await _bookingService.GetUpcomingStaysAsync(userId.Value);

			// Filter by property if specified (for landlord property details)
			if (propertyId.HasValue)
			{
				result = result.Where(b => b.PropertyId == propertyId.Value).ToList();
				_logger.LogInformation("User {UserId} retrieved {StayCount} upcoming stays for property {PropertyId}",
						userId, result.Count, propertyId.Value);
			}
			else
			{
				_logger.LogInformation("User {UserId} retrieved {StayCount} upcoming stays",
						userId, result.Count);
			}

			return Ok(result);
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Upcoming stays retrieval failed for user {UserId}", _currentUserService.UserId);
			return StatusCode(500, new { error = "An error occurred while retrieving upcoming stays" });
		}
	}

	/// <summary>
	/// Calculate refund amount for booking cancellation
	/// </summary>
	[HttpGet("{id}/refund-calculation")]
	[Authorize(Roles = "User,Tenant,Landlord")]
	public async Task<ActionResult<object>> CalculateRefundAmount(int id, [FromQuery] DateTime? cancellationDate = null)
	{
		try
		{
			var refundAmount = await _bookingService.CalculateRefundAmountAsync(id, cancellationDate);

			return Ok(new
			{
				BookingId = id,
				RefundAmount = refundAmount,
				CancellationDate = cancellationDate ?? DateTime.UtcNow
			});
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Refund calculation failed for booking {BookingId}", id);
			return StatusCode(500, new { error = "An error occurred while calculating refund amount" });
		}
	}

	/// <summary>
	/// Get current user's bookings
	/// </summary>
	[HttpGet("my-bookings")]
	public async Task<ActionResult<List<BookingResponse>>> GetMyBookings()
	{
		try
		{
			var result = await _bookingService.GetCurrentUserBookingsAsync();
			return Ok(result);
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error retrieving user bookings for {UserId}", _currentUserService.UserId);
			return StatusCode(500, new { error = "An error occurred while retrieving your bookings" });
		}
	}
}
