namespace eRents.Features.PaymentManagement.Models;

/// <summary>
/// Request to confirm/verify invoice payment after Stripe SDK completes
/// </summary>
public class ConfirmInvoicePaymentRequest
{
    /// <summary>
    /// The ID of the payment (invoice) to confirm
    /// </summary>
    public int PaymentId { get; set; }
}
