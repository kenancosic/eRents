using System;

namespace eRents.Features.BookingManagement.Models;

public class BookingRequest
{
    public int PropertyId { get; set; }
    public int UserId { get; set; }

    public DateOnly StartDate { get; set; }
    public DateOnly? EndDate { get; set; }

    public decimal TotalPrice { get; set; }

    public string PaymentMethod { get; set; } = "PayPal";
    public string Currency { get; set; } = "USD";

    // Status excluded from request per requirements
}