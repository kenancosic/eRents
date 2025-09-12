namespace eRents.Features.PaymentManagement.Models;

public class ConfirmPaymentRequest
{
    public string PayPalOrderId { get; set; } = string.Empty;
}
