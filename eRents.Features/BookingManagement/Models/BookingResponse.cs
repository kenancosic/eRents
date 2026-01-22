using System;
using eRents.Domain.Models.Enums;

namespace eRents.Features.BookingManagement.Models;

public class BookingResponse
{
    public int BookingId { get; set; }

    public int PropertyId { get; set; }
    public int UserId { get; set; }

    public DateOnly StartDate { get; set; }
    public DateOnly? EndDate { get; set; }
    public DateOnly? MinimumStayEndDate { get; set; }

    public decimal TotalPrice { get; set; }

    public BookingStatusEnum Status { get; set; }

    public string PaymentMethod { get; set; } = "Stripe";
    public string Currency { get; set; } = "USD";
    public string? PaymentStatus { get; set; }
    public string? PaymentReference { get; set; }

    /// <summary>
    /// Indicates if this booking is a subscription-based monthly rental.
    /// Only subscription bookings can be extended.
    /// </summary>
    public bool IsSubscription { get; set; }

    public DateTime CreatedAt { get; set; }
    public string CreatedBy { get; set; } = string.Empty;
    public DateTime UpdatedAt { get; set; }
    public string? UpdatedBy { get; set; }

    // Included from navigation properties
    public string? PropertyName { get; set; }
    public string? UserName { get; set; }
    
    /// <summary>
    /// Cover image ID for the property (use to construct image URL)
    /// </summary>
    public int? PropertyCoverImageId { get; set; }
}