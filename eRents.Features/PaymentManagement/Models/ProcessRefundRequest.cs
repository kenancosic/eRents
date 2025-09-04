using System;

namespace eRents.Features.PaymentManagement.Models;

public class ProcessRefundRequest
{
    public string? PaymentId { get; set; }
    public decimal Amount { get; set; }
    public string Currency { get; set; } = "USD";
    public string Reason { get; set; } = "Booking Cancellation";
}
