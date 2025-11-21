namespace eRents.Features.PaymentManagement.Services;

/// <summary>
/// Configuration options for Stripe payment integration
/// </summary>
public class StripeOptions
{
    /// <summary>
    /// Stripe secret key (sk_test_... or sk_live_...)
    /// </summary>
    public string SecretKey { get; set; } = string.Empty;
    
    /// <summary>
    /// Stripe publishable key (pk_test_... or pk_live_...)
    /// </summary>
    public string PublishableKey { get; set; } = string.Empty;
    
    /// <summary>
    /// Webhook signing secret for verifying webhook events (whsec_...)
    /// </summary>
    public string WebhookSecret { get; set; } = string.Empty;
    
    /// <summary>
    /// Stripe Connect client ID for OAuth (ca_...)
    /// </summary>
    public string ConnectClientId { get; set; } = string.Empty;
    
    /// <summary>
    /// Stripe API version to use
    /// </summary>
    public string ApiVersion { get; set; } = "2023-10-16";
    
    /// <summary>
    /// Currency code (default: USD)
    /// </summary>
    public string DefaultCurrency { get; set; } = "USD";
    
    /// <summary>
    /// Platform fee percentage (0-100)
    /// </summary>
    public decimal PlatformFeePercentage { get; set; } = 5.0m;
    
    /// <summary>
    /// Validates that all required configuration values are present
    /// </summary>
    /// <exception cref="InvalidOperationException">Thrown when required configuration is missing</exception>
    public void Validate()
    {
        if (string.IsNullOrWhiteSpace(SecretKey))
            throw new InvalidOperationException("Stripe SecretKey is required. Configure it in appsettings.json under Stripe:SecretKey");
            
        if (string.IsNullOrWhiteSpace(PublishableKey))
            throw new InvalidOperationException("Stripe PublishableKey is required. Configure it in appsettings.json under Stripe:PublishableKey");
            
        if (string.IsNullOrWhiteSpace(WebhookSecret))
            throw new InvalidOperationException("Stripe WebhookSecret is required. Configure it in appsettings.json under Stripe:WebhookSecret");
            
        if (PlatformFeePercentage < 0 || PlatformFeePercentage > 100)
            throw new InvalidOperationException("PlatformFeePercentage must be between 0 and 100");
    }
}
