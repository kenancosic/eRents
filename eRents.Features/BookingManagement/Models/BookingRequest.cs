using System;

namespace eRents.Features.BookingManagement.Models;

public class BookingRequest
{
    public int PropertyId { get; set; }
    public int UserId { get; set; }

    public DateOnly StartDate { get; set; }
    public DateOnly? EndDate { get; set; }

    public int NumberOfGuests { get; set; } = 1;
    public string? SpecialRequests { get; set; }

    public decimal TotalPrice { get; set; }

    public string PaymentMethod { get; set; } = "PayPal";
    public string Currency { get; set; } = "BAM";

    // Status excluded from request per requirements
}