using System.ComponentModel.DataAnnotations;
using eRents.Domain.Models.Enums;

namespace eRents.Features.RentalManagement.DTOs;

/// <summary>
/// Booking response DTO - aligned with actual Booking domain model
/// Consolidated from BookingManagement module
/// </summary>
public class BookingResponse
{
	public int Id { get; set; }
	public int BookingId { get; set; }
	public int PropertyId { get; set; }
	public int UserId { get; set; }
	public DateTime StartDate { get; set; }           // Maps from DateOnly StartDate
	public DateTime? EndDate { get; set; }            // Maps from DateOnly? EndDate
	public DateTime? MinimumStayEndDate { get; set; }  // Maps from DateOnly? MinimumStayEndDate
	public int NumberOfGuests { get; set; }
	public decimal TotalPrice { get; set; }
	public string Currency { get; set; } = "BAM";

	public BookingStatusEnum Status { get; set; }     // Enum instead of foreign key
	public string? PaymentStatus { get; set; }
	public string? PaymentMethod { get; set; }
	public string? PaymentReference { get; set; }
	public string? SpecialRequests { get; set; }
	public DateTime CreatedAt { get; set; }
	public DateTime UpdatedAt { get; set; }

	// Navigation properties (populated separately if needed)
	public string? StatusName { get; set; }          // From BookingStatus.StatusName
	public string? PropertyName { get; set; }        // From Property.Name (if included)
	public string? GuestName { get; set; }           // From User.FirstName + LastName (if included)
}

/// <summary>
/// Booking request for creating new bookings
/// </summary>
public class BookingRequest
{
	[Required]
	public int PropertyId { get; set; }

	[Required]
	public DateTime StartDate { get; set; }          // Will be converted to DateOnly

	[Required]
	public DateTime EndDate { get; set; }            // Will be converted to DateOnly

	[Required]
	[Range(1, 20)]
	public int NumberOfGuests { get; set; }

	[Required]
	[Range(0.01, 999999.99)]
	public decimal TotalPrice { get; set; }

	public string Currency { get; set; } = "BAM";

	[StringLength(1000)]
	public string? SpecialRequests { get; set; }

	[StringLength(50)]
	public string? PaymentMethod { get; set; }
}

/// <summary>
/// Booking update request
/// </summary>
public class BookingUpdateRequest
{
	public DateTime? StartDate { get; set; }         // Will be converted to DateOnly
	public DateTime? EndDate { get; set; }           // Will be converted to DateOnly

	[Range(1, 20)]
	public int? NumberOfGuests { get; set; }

	[Range(0.01, 999999.99)]
	public decimal? TotalPrice { get; set; }

	public string? Currency { get; set; }
	public BookingStatusEnum? Status { get; set; }   // Updated to use enum

	[StringLength(1000)]
	public string? SpecialRequests { get; set; }

	public string? PaymentStatus { get; set; }
	public string? PaymentMethod { get; set; }
	public string? PaymentReference { get; set; }
}

/// <summary>
/// Booking cancellation request
/// </summary>
public class BookingCancellationRequest
{
	[Required]
	public int BookingId { get; set; }

	[Required]
	[StringLength(500)]
	public string CancellationReason { get; set; } = string.Empty;

	public bool RequestRefund { get; set; }

	[StringLength(50)]
	public string? RefundMethod { get; set; }  // e.g., "PayPal", "Bank Transfer", "Credit Card"

	[StringLength(1000)]
	public string? AdditionalNotes { get; set; }
}

/// <summary>
/// Booking statistics response
/// </summary>
public class BookingStatisticsResponse
{
	public int TotalBookings { get; set; }
	public int ActiveBookings { get; set; }
	public int CompletedBookings { get; set; }
	public int CancelledBookings { get; set; }
	public decimal TotalRevenue { get; set; }
	public decimal PendingPayments { get; set; }
	public decimal RefundedAmount { get; set; }
	public double AverageBookingValue { get; set; }
	public double OccupancyRate { get; set; }
	public string Currency { get; set; } = "BAM";
}

#region Helper DTOs

/// <summary>
/// Date range for booked periods
/// </summary>
public class BookedDateRange
{
	public DateTime StartDate { get; set; }
	public DateTime EndDate { get; set; }
}

/// <summary>
/// Blocked date range response for availability checking
/// </summary>
public class BlockedDateRangeResponse
{
	public DateTime StartDate { get; set; }
	public DateTime EndDate { get; set; }
	public string? Reason { get; set; }
}

#endregion