using eRents.Features.BookingManagement.DTOs;
using eRents.Features.PropertyManagement.DTOs;
using eRents.Features.Shared.DTOs;

namespace eRents.Features.BookingManagement.Services;

/// <summary>
/// Interface for Booking entity operations
/// Supports dependency injection and testing patterns
/// </summary>
public interface IBookingService
{
	#region Public Booking Operations

	/// <summary>
	/// Get paginated bookings with filtering and sorting
	/// </summary>
	Task<PagedResponse<BookingResponse>> GetBookingsAsync(BookingSearchObject search);

	/// <summary>
	/// Get booking by ID with authorization check
	/// </summary>
	Task<BookingResponse?> GetBookingByIdAsync(int bookingId);

	/// <summary>
	/// Create new booking with availability check
	/// </summary>
	Task<BookingResponse> CreateBookingAsync(BookingRequest request);

	/// <summary>
	/// Update existing booking with authorization check
	/// </summary>
	Task<BookingResponse> UpdateBookingAsync(int bookingId, BookingUpdateRequest request);

	/// <summary>
	/// Cancel booking with refund calculation
	/// </summary>
	Task<BookingResponse> CancelBookingAsync(BookingCancellationRequest request);

	/// <summary>
	/// Delete booking (hard delete) with authorization check
	/// </summary>
	Task<bool> DeleteBookingAsync(int bookingId);

	/// <summary>
	/// Check property availability for date range
	/// </summary>
	Task<PropertyAvailabilityResponse> CheckPropertyAvailabilityAsync(
			int propertyId, DateTime startDate, DateTime endDate);

	/// <summary>
	/// Get current user's bookings
	/// </summary>
	Task<List<BookingResponse>> GetCurrentUserBookingsAsync();

	/// <summary>
	/// Get current active stays for a user (ongoing bookings)
	/// </summary>
	Task<List<BookingResponse>> GetCurrentStaysAsync(int userId);

	/// <summary>
	/// Get upcoming stays for a user (future bookings)
	/// </summary>
	Task<List<BookingResponse>> GetUpcomingStaysAsync(int userId);

	/// <summary>
	/// Calculate refund amount for booking cancellation
	/// </summary>
	Task<decimal> CalculateRefundAmountAsync(int bookingId, DateTime? cancellationDate = null);

	/// <summary>
	/// Simple property availability check
	/// </summary>
	Task<bool> IsPropertyAvailableAsync(int propertyId, DateOnly startDate, DateOnly endDate);

	/// <summary>
	/// Check if daily booking can be created for property and date range
	/// </summary>
	Task<bool> CanCreateDailyBookingAsync(int propertyId, DateOnly startDate, DateOnly endDate);

	/// <summary>
	/// Check if property supports daily rental type
	/// </summary>
	Task<bool> IsPropertyDailyRentalTypeAsync(int propertyId);

	/// <summary>
	/// Check if date range conflicts with annual rental
	/// </summary>
	Task<bool> HasConflictWithAnnualRentalAsync(int propertyId, DateOnly startDate, DateOnly endDate);

	#endregion
}