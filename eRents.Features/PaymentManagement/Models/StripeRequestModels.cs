namespace eRents.Features.PaymentManagement.Models;

/// <summary>
/// Request model for creating a Stripe payment intent
/// </summary>
public class CreateStripeIntentRequest
{
    public int BookingId { get; set; }
    public decimal Amount { get; set; }
    public string? Currency { get; set; }
    public Dictionary<string, string>? Metadata { get; set; }
}

/// <summary>
/// Request model for Stripe refunds
/// </summary>
public class StripeRefundRequest
{
    public int PaymentId { get; set; }
    public decimal? Amount { get; set; }
    public string? Reason { get; set; }
}

/// <summary>
/// Request model for Stripe Connect onboarding
/// </summary>
public class ConnectOnboardingRequest
{
    public string RefreshUrl { get; set; } = string.Empty;
    public string ReturnUrl { get; set; } = string.Empty;
}
