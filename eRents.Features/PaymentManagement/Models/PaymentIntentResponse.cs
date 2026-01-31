namespace eRents.Features.PaymentManagement.Models;

/// <summary>
/// Response model for Stripe payment intent operations
/// </summary>
public class PaymentIntentResponse
{
    /// <summary>
    /// The payment intent ID (pi_...)
    /// </summary>
    public string PaymentIntentId { get; set; } = string.Empty;
    
    /// <summary>
    /// Client secret for frontend SDK
    /// </summary>
    public string ClientSecret { get; set; } = string.Empty;
    
    /// <summary>
    /// Payment status
    /// </summary>
    public string Status { get; set; } = string.Empty;
    
    /// <summary>
    /// Amount in smallest currency unit (cents)
    /// </summary>
    public long Amount { get; set; }
    
    /// <summary>
    /// Currency code
    /// </summary>
    public string Currency { get; set; } = string.Empty;
    
    /// <summary>
    /// Optional error message
    /// </summary>
    public string? ErrorMessage { get; set; }
    
    /// <summary>
    /// Metadata attached to the payment intent
    /// </summary>
    public Dictionary<string, string>? Metadata { get; set; }
}

/// <summary>
/// Response model for booking created after successful payment
/// </summary>
public class BookingAfterPaymentResponse
{
    /// <summary>
    /// Whether the operation was successful
    /// </summary>
    public bool Success { get; set; }
    
    /// <summary>
    /// The created booking ID (null if creation failed)
    /// </summary>
    public int? BookingId { get; set; }
    
    /// <summary>
    /// The payment ID linked to the booking
    /// </summary>
    public int? PaymentId { get; set; }
    
    /// <summary>
    /// Status of the booking
    /// </summary>
    public string? Status { get; set; }
    
    /// <summary>
    /// Optional error message if creation failed
    /// </summary>
    public string? ErrorMessage { get; set; }
    
    /// <summary>
    /// Whether this was an existing booking (idempotency - already created by webhook)
    /// </summary>
    public bool WasAlreadyCreated { get; set; }
}

/// <summary>
/// Response model for refund operations
/// </summary>
public class RefundResponse
{
    /// <summary>
    /// The refund ID (re_...)
    /// </summary>
    public string RefundId { get; set; } = string.Empty;
    
    /// <summary>
    /// Amount refunded in smallest currency unit
    /// </summary>
    public long Amount { get; set; }
    
    /// <summary>
    /// Currency code
    /// </summary>
    public string Currency { get; set; } = string.Empty;
    
    /// <summary>
    /// Refund status
    /// </summary>
    public string Status { get; set; } = string.Empty;
    
    /// <summary>
    /// Reason for refund
    /// </summary>
    public string? Reason { get; set; }
    
    /// <summary>
    /// Optional error message
    /// </summary>
    public string? ErrorMessage { get; set; }
}
