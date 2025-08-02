using eRents.Domain.Models;
using eRents.Domain.Models.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using eRents.Domain.Shared.Interfaces;
using eRents.Features.Shared.DTOs;
using eRents.Features.Shared.Extensions;

namespace eRents.Features.Shared.Controllers
{
	[ApiController]
	[Route("[controller]")]
	public class BookingStatusController : ControllerBase
	{
		private readonly ILogger<BookingStatusController> _logger;
		private readonly ICurrentUserService _currentUserService;

		public BookingStatusController(
			ILogger<BookingStatusController> logger,
			ICurrentUserService currentUserService)
		{
			_logger = logger;
			_currentUserService = currentUserService;
		}

		/// <summary>
		/// Get all BookingStatuses for frontend dropdown/selection purposes
		/// </summary>
		[HttpGet]
		[Authorize] // BookingStatuses require authentication
		public async Task<ActionResult<object>> GetBookingStatuses()
		{
			return await this.ExecuteAsync(async () =>
			{
				var userId = _currentUserService.GetUserIdAsInt();
				_logger.LogInformation("Get booking statuses request by user {UserId}",
					userId > 0 ? userId.ToString() : "unknown");

				// Convert enum values to list
				var bookingStatuses = Enum.GetValues<BookingStatusEnum>()
					.Select(status => new
					{
						Id = (int)status,
						Name = status.ToString()
					})
					.OrderBy(bs => bs.Name)
					.ToList();

				_logger.LogInformation("Retrieved {Count} booking statuses for user {UserId}",
					bookingStatuses.Count, userId > 0 ? userId.ToString() : "unknown");

				return bookingStatuses;
			}, _logger, "GetBookingStatuses");
		}

		/// <summary>
		/// Get BookingStatus by ID
		/// </summary>
		[HttpGet("{id}")]
		[Authorize]
		public async Task<ActionResult<object>> GetBookingStatus(int id)
		{
			return await this.ExecuteAsync(async () =>
			{
				var userId = _currentUserService.GetUserIdAsInt();
				_logger.LogInformation("Get booking status by ID: {BookingStatusId} by user {UserId}",
					id, userId > 0 ? userId.ToString() : "unknown");

				// Validate enum value
				if (!Enum.IsDefined(typeof(BookingStatusEnum), id))
				{
					_logger.LogWarning("Booking status not found: {BookingStatusId} for user {UserId}",
						id, userId > 0 ? userId.ToString() : "unknown");
					throw new KeyNotFoundException($"Booking status with ID {id} not found");
				}

				var bookingStatus = (BookingStatusEnum)id;
				return new
				{
					Id = id,
					Name = bookingStatus.ToString()
				};
			}, _logger, "GetBookingStatus");
		}
	}
}