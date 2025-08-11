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

    public string PaymentMethod { get; set; } = "PayPal";
    public string Currency { get; set; } = "BAM";
    public string? PaymentStatus { get; set; }
    public string? PaymentReference { get; set; }

    public int NumberOfGuests { get; set; } = 1;
    public string? SpecialRequests { get; set; }

    public DateTime CreatedAt { get; set; }
    public string CreatedBy { get; set; } = string.Empty;
    public DateTime UpdatedAt { get; set; }
    public string? UpdatedBy { get; set; }
}