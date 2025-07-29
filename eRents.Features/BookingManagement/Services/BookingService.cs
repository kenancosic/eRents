using eRents.Domain.Models;
using eRents.Domain.Shared;
using eRents.Domain.Shared.Interfaces;
using eRents.Features.BookingManagement.DTOs;
using eRents.Features.BookingManagement.Mappers;
using eRents.Features.BookingManagement.Validators;
using eRents.Features.PropertyManagement.DTOs;
using eRents.Features.Shared.Services;
using eRents.Features.Shared.DTOs;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace eRents.Features.BookingManagement.Services
{
	public class BookingService : BaseService, IBookingService
	{
		public BookingService(
			ERentsContext context,
			IUnitOfWork unitOfWork,
			ICurrentUserService currentUserService,
			ILogger<BookingService> logger) : base(context, unitOfWork, currentUserService, logger)
		{
		}

        #region Public Booking Operations

        /// <summary>
        /// Get paginated bookings with filtering and sorting
        /// </summary>
        public async Task<PagedResponse<BookingResponse>> GetBookingsAsync(BookingSearchObject search)
        {
            try
            {
                var currentUserId = CurrentUserService.GetUserIdAsInt();
                var currentUserRole = CurrentUserService.UserRole;

                var query = Context.Bookings
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
                Logger.LogError(ex, "Error retrieving bookings for user {UserId}", CurrentUserService.UserId);
                throw;
            }
        }

        /// <summary>
        /// Get booking by ID with authorization check
        /// </summary>
        public async Task<BookingResponse?> GetBookingByIdAsync(int bookingId)
        {
            return await GetByIdAsync<Booking, BookingResponse>(
                bookingId,
                q => q.Include(b => b.BookingStatus).Include(b => b.Property).Include(b => b.User),
                async booking => await CanAccessBookingAsync(booking),
                booking => booking.ToResponse(),
                nameof(GetBookingByIdAsync)
            );
        }

        /// <summary>
        /// Create new booking with availability check
        /// </summary>
        public async Task<BookingResponse> CreateBookingAsync(BookingRequest request)
        {
            return await CreateAsync<Booking, BookingRequest, BookingResponse>(
                request,
                req => req.ToEntity(),
                async (booking, req) => {
                    await ValidateBookingAvailabilityAsync(req.PropertyId, req.StartDate, req.EndDate);
                    booking.UserId = CurrentUserId;
                    booking.BookingStatusId = await GetDefaultBookingStatusIdAsync();
                },
                booking => booking.ToResponse(),
                nameof(CreateBookingAsync)
            );
        }

        /// <summary>
        /// Update existing booking with authorization check
        /// </summary>
        public async Task<BookingResponse> UpdateBookingAsync(int bookingId, BookingUpdateRequest request)
        {
            return await UpdateAsync<Booking, BookingUpdateRequest, BookingResponse>(
                bookingId,
                request,
                q => q.Include(b => b.BookingStatus).Include(b => b.Property).Include(b => b.User),
                async booking => await CanAccessBookingAsync(booking),
                async (booking, req) => {
                    // Validate availability if dates are being changed
                    if (req.StartDate.HasValue || req.EndDate.HasValue)
                    {
                        var startDate = req.StartDate ?? booking.StartDate.ToDateTime(TimeOnly.MinValue);
                        var endDate = req.EndDate ?? booking.EndDate?.ToDateTime(TimeOnly.MinValue) ?? startDate.AddDays(1);
                        await ValidateBookingAvailabilityAsync(booking.PropertyId, startDate, endDate, bookingId);
                    }
                    req.UpdateEntity(booking);
                },
                booking => booking.ToResponse(),
                nameof(UpdateBookingAsync)
            );
        }

        /// <summary>
        /// Cancel booking with refund calculation
        /// </summary>
        public async Task<BookingResponse> CancelBookingAsync(BookingCancellationRequest request)
        {
            return await UnitOfWork.ExecuteInTransactionAsync(async () =>
            {
                try
                {
                    var currentUserId = CurrentUserService.GetUserIdAsInt();
                    var currentUserRole = CurrentUserService.UserRole;

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

                    await Context.SaveChangesAsync();

                    Logger.LogInformation("Booking {BookingId} cancelled by user {UserId}. Reason: {Reason}",
                                    request.BookingId, currentUserId, request.CancellationReason);

                    return booking.ToResponse();
                }
                catch (Exception ex)
                {
                    Logger.LogError(ex, "Error cancelling booking {BookingId} for user {UserId}",
                                    request.BookingId, CurrentUserService.UserId);
                    throw;
                }
            });
        }

        /// <summary>
        /// Delete booking (hard delete) with authorization check
        /// </summary>
        public async Task<bool> DeleteBookingAsync(int bookingId)
        {
            await DeleteAsync<Booking>(
                bookingId,
                async booking => await CanAccessBookingAsync(booking),
                nameof(DeleteBookingAsync)
            );
            return true;
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
                var conflictingBookings = await Context.Bookings
                        .Where(b => b.PropertyId == propertyId &&
                                   b.BookingStatus!.StatusName != "Cancelled" &&
                                   b.StartDate < endDateOnly &&
                                   (b.EndDate == null || b.EndDate > startDateOnly))
                        .Select(b => b.BookingId.ToString())
                        .ToListAsync();

                // Check if property is daily rental type
                var isDailyRental = await IsPropertyDailyRentalTypeAsync(propertyId);

                // Check for conflicts with annual rentals
                var hasAnnualConflict = await HasConflictWithAnnualRentalAsync(propertyId, startDateOnly, endDateOnly);

                return new PropertyAvailabilityResponse
                {
                    IsAvailable = !conflictingBookings.Any() && !hasAnnualConflict,
                    ConflictingBookingIds = conflictingBookings,
                    IsDailyRental = isDailyRental,
                    BlockedPeriods = await GetBlockedPeriodsAsync(propertyId, startDate, endDate)
                };
            }
            catch (Exception ex)
            {
                Logger.LogError(ex, "Error checking availability for property {PropertyId}", propertyId);
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
                var property = await Context.Properties
                        .Include(p => p.RentingType)
                        .FirstOrDefaultAsync(p => p.PropertyId == propertyId);

                if (property?.RentingType == null)
                    return false;

                // Check if the rental type is daily (assuming "Daily" is the name)
                return property.RentingType.TypeName?.ToLower() == "daily";
            }
            catch (Exception ex)
            {
                Logger.LogError(ex, "Error checking if property {PropertyId} is daily rental type", propertyId);
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
                var annualRentalConflicts = await Context.Bookings
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
                Logger.LogError(ex, "Error checking annual rental conflicts for property {PropertyId}", propertyId);
                throw;
            }
        }

        /// <summary>
        /// Check if property is available for the given date range
        /// </summary>
        public async Task<bool> IsPropertyAvailableAsync(int propertyId, DateTime startDate, DateTime endDate)
        {
            try
            {
                var availability = await CheckPropertyAvailabilityAsync(propertyId, startDate, endDate);
                return availability.IsAvailable;
            }
            catch (Exception ex)
            {
                Logger.LogError(ex, "Error checking property availability for property {PropertyId}", propertyId);
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
                var isDailyRental = await IsPropertyDailyRentalTypeAsync(propertyId);
                if (!isDailyRental)
                    return false;

                // Then check availability
                var startDateTime = startDate.ToDateTime(TimeOnly.MinValue);
                var endDateTime = endDate.ToDateTime(TimeOnly.MinValue);
                return await IsPropertyAvailableAsync(propertyId, startDateTime, endDateTime);
            }
            catch (Exception ex)
            {
                Logger.LogError(ex, "Error checking if daily booking can be created for property {PropertyId}", propertyId);
                throw;
            }
        }

        /// <summary>
        /// Get current stays for current user
        /// </summary>
        public async Task<List<BookingResponse>> GetCurrentStaysAsync()
        {
            try
            {
                var currentUserId = CurrentUserService.GetUserIdAsInt();
                var currentUserRole = CurrentUserService.UserRole;
                var today = DateOnly.FromDateTime(DateTime.UtcNow);

                var query = Context.Bookings
                        .Include(b => b.BookingStatus)
                        .Include(b => b.Property)
                        .Include(b => b.User)
                        .Where(b => b.StartDate <= today && 
                                   (b.EndDate == null || b.EndDate >= today) &&
                                   b.BookingStatus!.StatusName != "Cancelled")
                        .AsNoTracking();

                // Apply role-based filtering
                query = ApplyRoleBasedFiltering(query, currentUserRole, currentUserId.Value);

                var bookings = await query.ToListAsync();
                return bookings.ToResponseList();
            }
            catch (Exception ex)
            {
                Logger.LogError(ex, "Error retrieving current stays for user {UserId}", CurrentUserService.UserId);
                throw;
            }
        }

        /// <summary>
        /// Get upcoming stays for current user
        /// </summary>
        public async Task<List<BookingResponse>> GetUpcomingStaysAsync()
        {
            try
            {
                var currentUserId = CurrentUserService.GetUserIdAsInt();
                var currentUserRole = CurrentUserService.UserRole;
                var today = DateOnly.FromDateTime(DateTime.UtcNow);

                var query = Context.Bookings
                        .Include(b => b.BookingStatus)
                        .Include(b => b.Property)
                        .Include(b => b.User)
                        .Where(b => b.StartDate > today &&
                                   b.BookingStatus!.StatusName != "Cancelled")
                        .AsNoTracking();

                // Apply role-based filtering
                query = ApplyRoleBasedFiltering(query, currentUserRole, currentUserId.Value);

                var bookings = await query.OrderBy(b => b.StartDate).ToListAsync();
                return bookings.ToResponseList();
            }
            catch (Exception ex)
            {
                Logger.LogError(ex, "Error retrieving upcoming stays for user {UserId}", CurrentUserService.UserId);
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
                var cancellationDateTime = cancellationDate ?? DateTime.UtcNow;
                var currentUserId = CurrentUserService.GetUserIdAsInt();
                var currentUserRole = CurrentUserService.UserRole;

                var booking = await GetAuthorizedBookingAsync(bookingId, currentUserId.Value, currentUserRole);

                // Simple refund calculation logic (can be enhanced based on business rules)
                var bookingStartDate = booking.StartDate.ToDateTime(TimeOnly.MinValue);
                var daysDifference = (bookingStartDate - cancellationDateTime).Days;

                // Example refund policy:
                // - 100% refund if cancelled 7+ days before
                // - 50% refund if cancelled 1-6 days before
                // - 0% refund if cancelled same day or after start
                decimal refundPercentage = daysDifference switch
                {
                    >= 7 => 1.0m,
                    >= 1 => 0.5m,
                    _ => 0.0m
                };

                return booking.TotalPrice * refundPercentage;
            }
            catch (Exception ex)
            {
                Logger.LogError(ex, "Error calculating refund amount for booking {BookingId}", bookingId);
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
                var currentUserId = CurrentUserService.GetUserIdAsInt();

                var bookings = await Context.Bookings
                        .Include(b => b.BookingStatus)
                        .Include(b => b.Property)
                        .Include(b => b.User)
                        .Where(b => b.UserId == currentUserId.Value)
                        .OrderByDescending(b => b.CreatedAt)
                        .AsNoTracking()
                        .ToListAsync();

                return bookings.ToResponseList();
            }
            catch (Exception ex)
            {
                Logger.LogError(ex, "Error retrieving bookings for user {UserId}", CurrentUserService.UserId);
                throw;
            }
        }

	#endregion

	#region Helper Methods

	/// <summary>
	/// Check if current user can access the booking
	/// </summary>
	private async Task<bool> CanAccessBookingAsync(Booking booking)
	{
		var currentUserId = CurrentUserId;
		var currentUserRole = CurrentUserRole;

		return currentUserRole?.ToLower() switch
		{
			"landlord" => booking.Property?.OwnerId == currentUserId,
			"user" or "tenant" => booking.UserId == currentUserId,
			_ => booking.UserId == currentUserId // Default to user's own bookings
		};
	}

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
		IQueryable<Booking> query = Context.Bookings
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

		var conflictQuery = Context.Bookings
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
		var defaultStatus = await Context.BookingStatuses
				.FirstOrDefaultAsync(bs => bs.StatusName == "Pending");

		return defaultStatus?.BookingStatusId ?? 1;
	}

	/// <summary>
	/// Get booking status ID by name
	/// </summary>
	private async Task<int> GetBookingStatusIdByNameAsync(string statusName)
	{
		var status = await Context.BookingStatuses
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

		return await Context.Bookings
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
}
