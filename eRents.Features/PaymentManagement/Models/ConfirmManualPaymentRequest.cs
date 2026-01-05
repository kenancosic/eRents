namespace eRents.Features.PaymentManagement.Models;

/// <summary>
/// Request model for confirming manual payment received by landlord.
/// Used when Stripe is disabled and payments are collected offline.
/// </summary>
public class ConfirmManualPaymentRequest
{
    /// <summary>
    /// The booking ID for which payment is being confirmed.
    /// </summary>
    public int BookingId { get; set; }

    /// <summary>
    /// Optional reference for the payment (e.g., bank transfer reference, cash receipt number).
    /// </summary>
    public string? PaymentReference { get; set; }
}
