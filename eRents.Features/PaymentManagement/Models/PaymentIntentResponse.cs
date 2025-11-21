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
