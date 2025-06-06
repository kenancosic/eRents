using System;
using System.Collections.Generic;
using eRents.Domain.Shared;

namespace eRents.Domain.Models;

public partial class Booking : BaseEntity
{
    public int BookingId { get; set; }

    public int? PropertyId { get; set; }

    public int? UserId { get; set; }

    public DateOnly StartDate { get; set; }

    public DateOnly? EndDate { get; set; }

    public DateOnly? MinimumStayEndDate { get; set; }

    public decimal TotalPrice { get; set; }

    public DateOnly? BookingDate { get; set; }

    public int BookingStatusId { get; set; }

    // Payment Information (Optional - for PayPal tracking)
    public string PaymentMethod { get; set; } = "PayPal";
    public string Currency { get; set; } = "BAM";
    public string? PaymentStatus { get; set; }  // "Pending", "Completed", "Failed"
    public string? PaymentReference { get; set; }  // PayPal Transaction ID

    // Basic Booking Info
    public int NumberOfGuests { get; set; } = 1;
    public string? SpecialRequests { get; set; }

    // Navigation Properties
    public virtual Property? Property { get; set; }
    public virtual User? User { get; set; }
    public virtual BookingStatus BookingStatus { get; set; } = null!;
}
