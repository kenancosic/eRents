using eRents.Domain.Models;
using eRents.Domain.Shared;
using eRents.Domain.Shared.Interfaces;
using eRents.Features.BookingManagement.DTOs;
using eRents.Features.BookingManagement.Mappers;
using eRents.Features.PropertyManagement.DTOs;
using eRents.Features.Shared.DTOs;
using eRents.Features.Shared.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace eRents.Features.BookingManagement.Services;

/// <summary>
/// BookingService using ERentsContext directly - no repository layer
/// Follows modular architecture principles with clean separation of concerns
/// </summary>
public class BookingService : IBookingService
{
	private readonly ERentsContext _context;
	private readonly IUnitOfWork _unitOfWork;
	private readonly ICurrentUserService _currentUserService;
	private readonly ILogger<BookingService> _logger;

	public BookingService(
			ERentsContext context,
			IUnitOfWork unitOfWork,
			ICurrentUserService currentUserService,
			ILogger<BookingService> logger)
	{
		_context = context;
		_unitOfWork = unitOfWork;
		_currentUserService = currentUserService;
		_logger = logger;
	}

	#region Public Booking Operations

	/// <summary>
	/// Get paginated bookings with filtering and sorting
	/// </summary>
	public async Task<PagedResponse<BookingResponse>> GetBookingsAsync(BookingSearchObject search)
	{
		try
		{
			var currentUserId = _currentUserService.GetUserIdAsInt();
			var currentUserRole = _currentUserService.UserRole;

			var query = _context.Bookings
					.Include(b => b.BookingStatus)
					.Include(b => b.Property)
					.Include(b => b.User)
					.AsNoTracking();

			// Apply role-based filtering
			query = ApplyRoleBasedFiltering(query, currentUserRole, currentUserId.Value);

			// Apply search filters
			query = query.ApplySearchFilters(search);

			// Apply sorting
			query = query.ApplySorting(search.SortBy, search.SortDescending);

			// Get total count
			var totalCount = await query.CountAsync();

			// Apply pagination
			var bookings = await query
					.Skip((search.Page - 1) * search.PageSize)
					.Take(search.PageSize)
					.ToListAsync();

			var responseItems = bookings.ToResponseList();

			return new PagedResponse<BookingResponse>
			{
				Items = responseItems,
				TotalCount = totalCount,
				Page = search.Page,
				PageSize = search.PageSize
			};
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error retrieving bookings for user {UserId}", _currentUserService.UserId);
			throw;
		}
	}

	/// <summary>
	/// Get booking by ID with authorization check
	/// </summary>
	public async Task<BookingResponse?> GetBookingByIdAsync(int bookingId)
	{
		try
		{
			var currentUserId = _currentUserService.GetUserIdAsInt();
			var currentUserRole = _currentUserService.UserRole;

			var query = _context.Bookings
					.Include(b => b.BookingStatus)
					.Include(b => b.Property)
					.Include(b => b.User)
					.AsNoTracking();

			// Apply role-based filtering
			query = ApplyRoleBasedFiltering(query, currentUserRole, currentUserId.Value);

			var booking = await query.FirstOrDefaultAsync(b => b.BookingId == bookingId);

			return booking?.ToResponse();
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error retrieving booking {BookingId} for user {UserId}", bookingId, _currentUserService.UserId);
			throw;
		}
	}

	/// <summary>
	/// Create new booking with availability check
	/// </summary>
	public async Task<BookingResponse> CreateBookingAsync(BookingRequest request)
	{
		return await _unitOfWork.ExecuteInTransactionAsync(async () =>
		{
			try
			{
				var currentUserId = _currentUserService.GetUserIdAsInt();

				// Check property availability
				await ValidateBookingAvailabilityAsync(request.PropertyId, request.StartDate, request.EndDate);

				// Create booking entity
				var booking = request.ToEntity();
				booking.UserId = currentUserId.Value;
				booking.BookingStatusId = await GetDefaultBookingStatusIdAsync();
				_context.Bookings.Add(booking);
				await _context.SaveChangesAsync();

				_logger.LogInformation("Booking {BookingId} created successfully for user {UserId} and property {PropertyId}",
								booking.BookingId, currentUserId, request.PropertyId);

				return booking.ToResponse();
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error creating booking for user {UserId} and property {PropertyId}",
								_currentUserService.UserId, request.PropertyId);
				throw;
			}
		});
	}

	/// <summary>
	/// Update existing booking with authorization check
	/// </summary>
	public async Task<BookingResponse> UpdateBookingAsync(int bookingId, BookingUpdateRequest request)
	{
		return await _unitOfWork.ExecuteInTransactionAsync(async () =>
		{
			try
			{
				var currentUserId = _currentUserService.GetUserIdAsInt();
				var currentUserRole = _currentUserService.UserRole;

				// Get booking with authorization check
				var booking = await GetAuthorizedBookingAsync(bookingId, currentUserId.Value, currentUserRole);

				// Validate availability if dates are being changed
				if (request.StartDate.HasValue || request.EndDate.HasValue)
				{
					var startDate = request.StartDate ?? booking.StartDate.ToDateTime(TimeOnly.MinValue);
					var endDate = request.EndDate ?? booking.EndDate?.ToDateTime(TimeOnly.MinValue) ?? startDate.AddDays(1);

					await ValidateBookingAvailabilityAsync(booking.PropertyId, startDate, endDate, bookingId);
				}

				// Update booking
				request.UpdateEntity(booking);
				await _context.SaveChangesAsync();

				_logger.LogInformation("Booking {BookingId} updated successfully by user {UserId}",
								bookingId, currentUserId);

				return booking.ToResponse();
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error updating booking {BookingId} for user {UserId}", bookingId, _currentUserService.UserId);
				throw;
			}
		});
	}

	/// <summary>
	/// Cancel booking with refund calculation
	/// </summary>
	public async Task<BookingResponse> CancelBookingAsync(BookingCancellationRequest request)
	{
		return await _unitOfWork.ExecuteInTransactionAsync(async () =>
		{
			try
			{
				var currentUserId = _currentUserService.GetUserIdAsInt();
				var currentUserRole = _currentUserService.UserRole;

				// Get booking with authorization check
				var booking = await GetAuthorizedBookingAsync(request.BookingId, currentUserId.Value, currentUserRole);

				// Update booking status to cancelled
				var cancelledStatusId = await GetBookingStatusIdByNameAsync("Cancelled");
				booking.BookingStatusId = cancelledStatusId;

				// Add cancellation notes to special requests
				var cancellationNote = $"Cancelled: {request.CancellationReason}";
				if (!string.IsNullOrEmpty(request.AdditionalNotes))
					cancellationNote += $" - {request.AdditionalNotes}";

				booking.SpecialRequests = string.IsNullOrEmpty(booking.SpecialRequests)
								? cancellationNote
								: $"{booking.SpecialRequests}\n{cancellationNote}";

				await _context.SaveChangesAsync();

				_logger.LogInformation("Booking {BookingId} cancelled by user {UserId}. Reason: {Reason}",
								request.BookingId, currentUserId, request.CancellationReason);

				return booking.ToResponse();
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error cancelling booking {BookingId} for user {UserId}",
								request.BookingId, _currentUserService.UserId);
				throw;
			}
		});
	}

	/// <summary>
	/// Delete booking (hard delete) with authorization check
	/// </summary>
	public async Task<bool> DeleteBookingAsync(int bookingId)
	{
		return await _unitOfWork.ExecuteInTransactionAsync(async () =>
		{
			try
			{
				var currentUserId = _currentUserService.GetUserIdAsInt();
				var currentUserRole = _currentUserService.UserRole;

				// Get booking with authorization check
				var booking = await GetAuthorizedBookingAsync(bookingId, currentUserId.Value, currentUserRole);

				_context.Bookings.Remove(booking);
				await _context.SaveChangesAsync();

				_logger.LogInformation("Booking {BookingId} deleted by user {UserId}", bookingId, currentUserId);

				return true;
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error deleting booking {BookingId} for user {UserId}", bookingId, _currentUserService.UserId);
				throw;
			}
		});
	}

	/// <summary>
	/// Check property availability for date range
	/// </summary>
	public async Task<PropertyAvailabilityResponse> CheckPropertyAvailabilityAsync(
			int propertyId, DateTime startDate, DateTime endDate)
	{
		try
		{
			var startDateOnly = DateOnly.FromDateTime(startDate);
			var endDateOnly = DateOnly.FromDateTime(endDate);

			// Check for conflicting bookings
			var conflictingBookings = await _context.Bookings
					.Where(b => b.PropertyId == propertyId &&
										 b.BookingStatus!.StatusName != "Cancelled" &&
										 b.StartDate < endDateOnly &&
										 (b.EndDate == null || b.EndDate > startDateOnly))
					.Select(b => b.BookingId.ToString())
					.ToListAsync();

			var isAvailable = !conflictingBookings.Any();

			return new PropertyAvailabilityResponse
			{
				PropertyId = propertyId,
				IsAvailable = isAvailable,
				BlockedPeriods = isAvailable ? new List<BlockedDateRangeResponse>() : await GetBlockedPeriodsAsync(propertyId, startDate, endDate)
			};
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error checking availability for property {PropertyId}", propertyId);
			throw;
		}
	}

	/// <summary>
	/// Get current user's bookings
	/// </summary>
	public async Task<List<BookingResponse>> GetCurrentUserBookingsAsync()
	{
		try
		{
			var currentUserId = _currentUserService.GetUserIdAsInt();

			var bookings = await _context.Bookings
					.Include(b => b.BookingStatus)
					.Include(b => b.Property)
					.Where(b => b.UserId == currentUserId)
					.OrderByDescending(b => b.CreatedAt)
					.AsNoTracking()
					.ToListAsync();

			return bookings.ToResponseList();
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error retrieving current user bookings");
			throw;
		}
	}

	/// <summary>
	/// Get current active stays for user
	/// </summary>
	public async Task<List<BookingResponse>> GetCurrentStaysAsync(int userId)
	{
		try
		{
			var currentDate = DateOnly.FromDateTime(DateTime.UtcNow);

			var currentStays = await _context.Bookings
					.Where(b => b.UserId == userId &&
										 b.StartDate <= currentDate &&
										 (b.EndDate == null || b.EndDate >= currentDate) &&
										 b.BookingStatus.StatusName != "Cancelled")
					.Include(b => b.Property)
					.Include(b => b.BookingStatus)
					.OrderBy(b => b.StartDate)
					.AsNoTracking()
					.ToListAsync();

			return currentStays.ToResponseList();
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error retrieving current stays for user {UserId}", userId);
			throw;
		}
	}

	/// <summary>
	/// Get upcoming stays for user
	/// </summary>
	public async Task<List<BookingResponse>> GetUpcomingStaysAsync(int userId)
	{
		try
		{
			var currentDate = DateOnly.FromDateTime(DateTime.UtcNow);

			var upcomingStays = await _context.Bookings
					.Where(b => b.UserId == userId &&
										 b.StartDate > currentDate &&
										 b.BookingStatus.StatusName != "Cancelled")
					.Include(b => b.Property)
					.Include(b => b.BookingStatus)
					.OrderBy(b => b.StartDate)
					.AsNoTracking()
					.ToListAsync();

			return upcomingStays.ToResponseList();
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error retrieving upcoming stays for user {UserId}", userId);
			throw;
		}
	}

	/// <summary>
	/// Calculate refund amount for booking cancellation
	/// </summary>
	public async Task<decimal> CalculateRefundAmountAsync(int bookingId, DateTime? cancellationDate = null)
	{
		try
		{
			var currentUserId = _currentUserService.GetUserIdAsInt();

			var booking = await _context.Bookings
					.FirstOrDefaultAsync(b => b.BookingId == bookingId);

			if (booking == null)
				return 0;

			var cancelDate = cancellationDate ?? DateTime.UtcNow;
			var startDate = booking.StartDate.ToDateTime(TimeOnly.MinValue);
			var daysUntilStart = (startDate - cancelDate).Days;

			// Basic refund calculation logic
			if (daysUntilStart >= 30)
				return booking.TotalPrice; // Full refund for 30+ days notice
			else if (daysUntilStart >= 14)
				return booking.TotalPrice * 0.75m; // 75% refund for 14-29 days notice
			else if (daysUntilStart >= 7)
				return booking.TotalPrice * 0.50m; // 50% refund for 7-13 days notice
			else if (daysUntilStart >= 1)
				return booking.TotalPrice * 0.25m; // 25% refund for 1-6 days notice
			else
				return 0; // No refund for same-day cancellation

		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error calculating refund for booking {BookingId}", bookingId);
			throw;
		}
	}

	/// <summary>
	/// Simple property availability check
	/// </summary>
	public async Task<bool> IsPropertyAvailableAsync(int propertyId, DateOnly startDate, DateOnly endDate)
	{
		try
		{
			var conflictingBookings = await _context.Bookings
					.Where(b => b.PropertyId == propertyId &&
										 b.BookingStatus!.StatusName != "Cancelled" &&
										 ((b.StartDate <= endDate && (b.EndDate == null || b.EndDate >= startDate))))
					.AnyAsync();

			return !conflictingBookings;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error checking availability for property {PropertyId}", propertyId);
			throw;
		}
	}

	/// <summary>
	/// Check if daily booking can be created for property and date range
	/// </summary>
	public async Task<bool> CanCreateDailyBookingAsync(int propertyId, DateOnly startDate, DateOnly endDate)
	{
		try
		{
			// First check if property supports daily rentals
			var isDaily = await IsPropertyDailyRentalTypeAsync(propertyId);
			if (!isDaily)
				return false;

			// Check if property is available for the dates
			var isAvailable = await IsPropertyAvailableAsync(propertyId, startDate, endDate);
			if (!isAvailable)
				return false;

			// Check for conflicts with annual rentals
			var hasAnnualConflict = await HasConflictWithAnnualRentalAsync(propertyId, startDate, endDate);
			if (hasAnnualConflict)
				return false;

			return true;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error checking if daily booking can be created for property {PropertyId}", propertyId);
			throw;
		}
	}

	/// <summary>
	/// Check if property supports daily rental type
	/// </summary>
	public async Task<bool> IsPropertyDailyRentalTypeAsync(int propertyId)
	{
		try
		{
			var property = await _context.Properties
					.Include(p => p.RentingType)
					.FirstOrDefaultAsync(p => p.PropertyId == propertyId);

			if (property?.RentingType == null)
				return false;

			// Check if the rental type is daily (assuming "Daily" is the name)
			return property.RentingType.TypeName?.ToLower() == "daily";
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error checking if property {PropertyId} is daily rental type", propertyId);
			throw;
		}
	}

	/// <summary>
	/// Check if date range conflicts with annual rental
	/// </summary>
	public async Task<bool> HasConflictWithAnnualRentalAsync(int propertyId, DateOnly startDate, DateOnly endDate)
	{
		try
		{
			// Check for existing bookings with annual rental type that overlap with the date range
			var annualRentalConflicts = await _context.Bookings
					.Include(b => b.Property)
					.ThenInclude(p => p!.RentingType)
					.Where(b => b.PropertyId == propertyId &&
										 b.BookingStatus!.StatusName != "Cancelled" &&
										 b.Property!.RentingType!.TypeName.ToLower() == "annual" &&
										 b.StartDate < endDate &&
										 (b.EndDate == null || b.EndDate > startDate))
					.AnyAsync();

			return annualRentalConflicts;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error checking annual rental conflicts for property {PropertyId}", propertyId);
			throw;
		}
	}

	#endregion

	#region Helper Methods

	/// <summary>
	/// Apply role-based filtering to booking queries
	/// </summary>
	private IQueryable<Booking> ApplyRoleBasedFiltering(IQueryable<Booking> query, string? userRole, int userId)
	{
		return userRole?.ToLower() switch
		{
			"landlord" => query.Where(b => b.Property!.OwnerId == userId),
			"user" or "tenant" => query.Where(b => b.UserId == userId),
			_ => query.Where(b => b.UserId == userId) // Default to user's own bookings
		};
	}

	/// <summary>
	/// Get booking with authorization check
	/// </summary>
	private async Task<Booking> GetAuthorizedBookingAsync(int bookingId, int currentUserId, string? userRole)
	{
		IQueryable<Booking> query = _context.Bookings
				.Include(b => b.Property)
				.Include(b => b.BookingStatus);

		// Apply role-based filtering
		query = ApplyRoleBasedFiltering(query, userRole, currentUserId);

		var booking = await query.FirstOrDefaultAsync(b => b.BookingId == bookingId);

		if (booking == null)
			throw new UnauthorizedAccessException("Booking not found or access denied");

		return booking;
	}

	/// <summary>
	/// Validate booking availability for date range
	/// </summary>
	private async Task ValidateBookingAvailabilityAsync(int propertyId, DateTime startDate, DateTime endDate, int? excludeBookingId = null)
	{
		var startDateOnly = DateOnly.FromDateTime(startDate);
		var endDateOnly = DateOnly.FromDateTime(endDate);

		var conflictQuery = _context.Bookings
				.Where(b => b.PropertyId == propertyId &&
									 b.BookingStatus!.StatusName != "Cancelled" &&
									 b.StartDate < endDateOnly &&
									 (b.EndDate == null || b.EndDate > startDateOnly));

		if (excludeBookingId.HasValue)
			conflictQuery = conflictQuery.Where(b => b.BookingId != excludeBookingId.Value);

		var hasConflict = await conflictQuery.AnyAsync();

		if (hasConflict)
			throw new InvalidOperationException("Property is not available for the selected dates");
	}

	/// <summary>
	/// Get default booking status ID (Pending)
	/// </summary>
	private async Task<int> GetDefaultBookingStatusIdAsync()
	{
		var defaultStatus = await _context.BookingStatuses
				.FirstOrDefaultAsync(bs => bs.StatusName == "Pending");

		return defaultStatus?.BookingStatusId ?? 1;
	}

	/// <summary>
	/// Get booking status ID by name
	/// </summary>
	private async Task<int> GetBookingStatusIdByNameAsync(string statusName)
	{
		var status = await _context.BookingStatuses
				.FirstOrDefaultAsync(bs => bs.StatusName == statusName);

		return status?.BookingStatusId ?? 1;
	}



	/// <summary>
	/// Get blocked periods for property in date range
	/// </summary>
	private async Task<List<BlockedDateRangeResponse>> GetBlockedPeriodsAsync(int propertyId, DateTime startDate, DateTime endDate)
	{
		var startDateOnly = DateOnly.FromDateTime(startDate);
		var endDateOnly = DateOnly.FromDateTime(endDate);

		return await _context.Bookings
				.Where(b => b.PropertyId == propertyId &&
									 b.BookingStatus!.StatusName != "Cancelled" &&
									 b.StartDate < endDateOnly &&
									 (b.EndDate == null || b.EndDate > startDateOnly))
				.Select(b => new BlockedDateRangeResponse
				{
					StartDate = b.StartDate.ToDateTime(TimeOnly.MinValue),
					EndDate = (b.EndDate ?? b.StartDate.AddDays(1)).ToDateTime(TimeOnly.MinValue),
					Reason = "Booking"
				})
				.ToListAsync();
	}

	#endregion
}
