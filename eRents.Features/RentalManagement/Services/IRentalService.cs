using eRents.Features.RentalManagement.DTOs;
using eRents.Features.PropertyManagement.DTOs;
using eRents.Features.Shared.DTOs;

namespace eRents.Features.RentalManagement.Services;

/// <summary>
/// Consolidated interface for rental and booking management
/// Combines annual rental requests and daily bookings under unified service
/// </summary>
public interface IRentalService
{
	#region Rental Request Operations (Annual Leases)

	/// <summary>
	/// Get rental request by ID
	/// </summary>
	Task<RentalRequestResponse?> GetRentalRequestByIdAsync(int rentalRequestId);

	/// <summary>
	/// Create new rental request
	/// </summary>
	Task<RentalRequestResponse> CreateRentalRequestAsync(RentalRequestRequest request);

	/// <summary>
	/// Update existing rental request
	/// </summary>
	Task<RentalRequestResponse> UpdateRentalRequestAsync(int rentalRequestId, RentalRequestRequest request);

	/// <summary>
	/// Delete rental request
	/// </summary>
	Task<bool> DeleteRentalRequestAsync(int rentalRequestId);

	/// <summary>
	/// Get paginated rental requests with filtering
	/// </summary>
	Task<PagedResponse<RentalRequestResponse>> GetRentalRequestsAsync(RentalFilterRequest filter);

	/// <summary>
	/// Get rental requests for specific property
	/// </summary>
	Task<List<RentalRequestResponse>> GetPropertyRentalRequestsAsync(int propertyId);

	/// <summary>
	/// Get pending rental requests requiring action
	/// </summary>
	Task<List<RentalRequestResponse>> GetPendingRentalRequestsAsync();

	/// <summary>
	/// Get expired rental requests
	/// </summary>
	Task<List<RentalRequestResponse>> GetExpiredRentalRequestsAsync();

	/// <summary>
	/// Approve rental request
	/// </summary>
	Task<RentalRequestResponse> ApproveRentalRequestAsync(int rentalRequestId, RentalApprovalRequest approval);

	/// <summary>
	/// Reject rental request
	/// </summary>
	Task<RentalRequestResponse> RejectRentalRequestAsync(int rentalRequestId, RentalApprovalRequest rejection);

	/// <summary>
	/// Cancel rental request
	/// </summary>
	Task<RentalRequestResponse> CancelRentalRequestAsync(int rentalRequestId, string? reason = null);

	/// <summary>
	/// Check if user can approve rental request
	/// </summary>
	Task<bool> CanApproveRentalRequestAsync(int rentalRequestId, int userId);

	/// <summary>
	/// Validate rental request before creation
	/// </summary>
	Task<(bool IsValid, List<string> ValidationErrors)> ValidateRentalRequestAsync(RentalRequestRequest request);

	/// <summary>
	/// Calculate total price for rental request
	/// </summary>
	Task<decimal> CalculateRentalPriceAsync(int propertyId, DateTime startDate, DateTime endDate, int numberOfGuests);

	#endregion

	#region Booking Operations (Daily Rentals)

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
	/// Get current user's bookings
	/// </summary>
	Task<List<BookingResponse>> GetCurrentUserBookingsAsync();

	/// <summary>
	/// Get current active stays for current user (ongoing bookings)
	/// </summary>
	Task<List<BookingResponse>> GetCurrentStaysAsync();

	/// <summary>
	/// Get upcoming stays for current user (future bookings)
	/// </summary>
	Task<List<BookingResponse>> GetUpcomingStaysAsync();

	/// <summary>
	/// Calculate refund amount for booking cancellation
	/// </summary>
	Task<decimal> CalculateRefundAmountAsync(int bookingId, DateTime? cancellationDate = null);

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

	#region Unified Availability Operations

	/// <summary>
	/// Check property availability for date range (supports both daily and annual)
	/// </summary>
	Task<PropertyAvailabilityResponse> CheckPropertyAvailabilityAsync(int propertyId, DateTime startDate, DateTime endDate);

	/// <summary>
	/// Simple property availability check (supports both daily and annual)
	/// </summary>
	Task<bool> IsPropertyAvailableAsync(int propertyId, DateTime startDate, DateTime endDate);

	#endregion
}