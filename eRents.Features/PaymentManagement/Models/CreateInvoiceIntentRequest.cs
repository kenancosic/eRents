namespace eRents.Features.PaymentManagement.Models;

/// <summary>
/// Request to create Stripe payment intent for an existing pending invoice
/// </summary>
public class CreateInvoiceIntentRequest
{
    /// <summary>
    /// The ID of the existing pending payment (invoice) to pay
    /// </summary>
    public int PaymentId { get; set; }
}
