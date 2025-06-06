using eRents.Domain.Models;
using eRents.WebApi.Controllers.Base;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using eRents.Shared.Services;
using eRents.Shared.DTO.Response;

namespace eRents.WebApi.Controllers
{
	[ApiController]
	[Route("[controller]")]
	public class BookingStatusController : ControllerBase
	{
		private readonly ERentsContext _context;
		private readonly ILogger<BookingStatusController> _logger;
		private readonly ICurrentUserService _currentUserService;

		public BookingStatusController(
			ERentsContext context,
			ILogger<BookingStatusController> logger,
			ICurrentUserService currentUserService)
		{
			_context = context;
			_logger = logger;
			_currentUserService = currentUserService;
		}

		/// <summary>
		/// Get all BookingStatuses for frontend dropdown/selection purposes
		/// </summary>
		[HttpGet]
		[Authorize] // BookingStatuses require authentication
		public async Task<IActionResult> GetBookingStatuses()
		{
			try
			{
				_logger.LogInformation("Get booking statuses request by user {UserId}", 
					_currentUserService.UserId ?? "unknown");

				var bookingStatuses = await _context.BookingStatuses
					.AsNoTracking()
					.OrderBy(bs => bs.StatusName)
					.ToListAsync();

				var response = bookingStatuses.Select(bs => new
				{
					Id = bs.BookingStatusId,
					Name = bs.StatusName
				}).ToList();

				_logger.LogInformation("Retrieved {Count} booking statuses for user {UserId}", 
					response.Count, _currentUserService.UserId ?? "unknown");

				return Ok(response);
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error retrieving booking statuses for user {UserId}", 
					_currentUserService.UserId ?? "unknown");
				return StatusCode(500, new StandardErrorResponse
				{
					Type = "Internal",
					Message = "An error occurred while retrieving booking statuses",
					Timestamp = DateTime.UtcNow,
					TraceId = HttpContext.TraceIdentifier,
					Path = Request.Path.Value
				});
			}
		}

		/// <summary>
		/// Get BookingStatus by ID
		/// </summary>
		[HttpGet("{id}")]
		[Authorize]
		public async Task<IActionResult> GetBookingStatus(int id)
		{
			try
			{
				_logger.LogInformation("Get booking status by ID: {BookingStatusId} by user {UserId}", 
					id, _currentUserService.UserId ?? "unknown");

				var bookingStatus = await _context.BookingStatuses
					.AsNoTracking()
					.FirstOrDefaultAsync(bs => bs.BookingStatusId == id);

				if (bookingStatus == null)
				{
					_logger.LogWarning("Booking status not found: {BookingStatusId} for user {UserId}", 
						id, _currentUserService.UserId ?? "unknown");
					return NotFound(new StandardErrorResponse
					{
						Type = "NotFound",
						Message = "Booking status not found",
						Timestamp = DateTime.UtcNow,
						TraceId = HttpContext.TraceIdentifier,
						Path = Request.Path.Value
					});
				}

				var response = new
				{
					Id = bookingStatus.BookingStatusId,
					Name = bookingStatus.StatusName
				};

				return Ok(response);
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error retrieving booking status {BookingStatusId} for user {UserId}", 
					id, _currentUserService.UserId ?? "unknown");
				return StatusCode(500, new StandardErrorResponse
				{
					Type = "Internal",
					Message = "An error occurred while retrieving the booking status",
					Timestamp = DateTime.UtcNow,
					TraceId = HttpContext.TraceIdentifier,
					Path = Request.Path.Value
				});
			}
		}
	}
} 