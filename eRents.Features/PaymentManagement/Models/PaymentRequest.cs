namespace eRents.Features.PaymentManagement.Models;

public class PaymentRequest
{
    public int? TenantId { get; set; }
    public int? PropertyId { get; set; }
    public int? BookingId { get; set; }

    public decimal Amount { get; set; }
    public string Currency { get; set; } = string.Empty;
    public string PaymentMethod { get; set; } = string.Empty;

    public string? PaymentStatus { get; set; }
    public string? PaymentReference { get; set; }

    // PaymentType default is BookingPayment; for refunds use "Refund"
    public string PaymentType { get; set; } = "BookingPayment";

    public int? OriginalPaymentId { get; set; }
    public string? RefundReason { get; set; }
}