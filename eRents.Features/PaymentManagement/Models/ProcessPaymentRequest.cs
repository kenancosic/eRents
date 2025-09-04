namespace eRents.Features.PaymentManagement.Models;

public class ProcessPaymentRequest
{
    public int BookingId { get; set; }
    public decimal Amount { get; set; }
    public string Currency { get; set; } = "USD";
    public string Description { get; set; } = "Property Booking Payment";
}
