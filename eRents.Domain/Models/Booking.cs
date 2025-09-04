using System;
using System.Collections.Generic;
using eRents.Domain.Shared;
using eRents.Domain.Models.Enums;

namespace eRents.Domain.Models;

public partial class Booking : BaseEntity
{
    public int BookingId { get; set; }

    public int PropertyId { get; set; }

    public int UserId { get; set; }

    public DateOnly StartDate { get; set; }

    public DateOnly? EndDate { get; set; }

    public DateOnly? MinimumStayEndDate { get; set; }

    public decimal TotalPrice { get; set; }

    // Replaced BookingStatusId foreign key with enum
    public BookingStatusEnum Status { get; set; } = BookingStatusEnum.Upcoming;

    // Payment Information (Optional - for PayPal tracking)
    public string PaymentMethod { get; set; } = "PayPal";
    public string Currency { get; set; } = "BAM";
    public string? PaymentStatus { get; set; }  // "Pending", "Completed", "Failed"
    public string? PaymentReference { get; set; }  // PayPal Transaction ID

    // For monthly rentals, track if this is a subscription-based booking
    public bool IsSubscription { get; set; } = false;
    
    // For subscription bookings, link to the subscription
    public int? SubscriptionId { get; set; }
    public virtual Subscription? Subscription { get; set; }

    // Basic Booking Info
    public int NumberOfGuests { get; set; } = 1;
    public string? SpecialRequests { get; set; }

    // Navigation Properties
    public virtual Property Property { get; set; } = null!;
    public virtual User User { get; set; } = null!;
    public virtual ICollection<Payment> Payments { get; set; } = new List<Payment>();
}
