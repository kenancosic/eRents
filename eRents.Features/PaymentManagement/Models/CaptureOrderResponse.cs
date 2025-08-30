namespace eRents.Features.PaymentManagement.Models;

public class CaptureOrderResponse
{
    public string? CaptureId { get; set; }
    public string? Status { get; set; }
    public string? PayerEmail { get; set; }
    public string? PayerName { get; set; }
}
