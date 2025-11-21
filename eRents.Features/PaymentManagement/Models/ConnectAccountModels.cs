namespace eRents.Features.PaymentManagement.Models;

/// <summary>
/// Response model for Stripe Connect onboarding
/// </summary>
public class ConnectOnboardingResponse
{
    /// <summary>
    /// The Stripe account ID (acct_...)
    /// </summary>
    public string AccountId { get; set; } = string.Empty;
    
    /// <summary>
    /// Onboarding URL for the landlord to complete setup
    /// </summary>
    public string OnboardingUrl { get; set; } = string.Empty;
    
    /// <summary>
    /// Expiration timestamp for the onboarding link
    /// </summary>
    public long ExpiresAt { get; set; }
    
    /// <summary>
    /// Optional error message
    /// </summary>
    public string? ErrorMessage { get; set; }
}

/// <summary>
/// Status information for a connected account
/// </summary>
public class ConnectAccountStatus
{
    /// <summary>
    /// The Stripe account ID
    /// </summary>
    public string? AccountId { get; set; }
    
    /// <summary>
    /// Whether the account is active and can receive payments
    /// </summary>
    public bool IsActive { get; set; }
    
    /// <summary>
    /// Whether charges are enabled
    /// </summary>
    public bool ChargesEnabled { get; set; }
    
    /// <summary>
    /// Whether payouts are enabled
    /// </summary>
    public bool PayoutsEnabled { get; set; }
    
    /// <summary>
    /// Whether details have been submitted
    /// </summary>
    public bool DetailsSubmitted { get; set; }
    
    /// <summary>
    /// Current requirements for the account
    /// </summary>
    public List<string>? CurrentlyDue { get; set; }
    
    /// <summary>
    /// Eventually due requirements
    /// </summary>
    public List<string>? EventuallyDue { get; set; }
    
    /// <summary>
    /// Human-readable status message
    /// </summary>
    public string StatusMessage { get; set; } = string.Empty;
    
    /// <summary>
    /// Optional error message
    /// </summary>
    public string? ErrorMessage { get; set; }
}
