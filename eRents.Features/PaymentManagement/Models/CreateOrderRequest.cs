namespace eRents.Features.PaymentManagement.Models;

public class CreateOrderRequest
{
    public int BookingId { get; set; }
    
    // Optional override values; if null/empty, the service will derive them from the booking
    public decimal? Amount { get; set; }
    public string? Currency { get; set; }
    public string? Description { get; set; }
}
