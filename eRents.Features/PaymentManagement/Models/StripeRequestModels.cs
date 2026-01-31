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

/// <summary>
/// Request model for creating a Stripe payment intent with availability check
/// Booking is NOT created - only payment intent with availability validation
/// </summary>
public class CreatePaymentIntentWithCheckRequest
{
    public int PropertyId { get; set; }
    public DateOnly StartDate { get; set; }
    public DateOnly? EndDate { get; set; }
    public decimal Amount { get; set; }
    public string? Currency { get; set; }
    public Dictionary<string, string>? Metadata { get; set; }
}

/// <summary>
/// Request model for confirming booking after successful payment
/// </summary>
public class ConfirmBookingAfterPaymentRequest
{
    public string PaymentIntentId { get; set; } = string.Empty;
    public int PropertyId { get; set; }
    public DateOnly StartDate { get; set; }
    public DateOnly? EndDate { get; set; }
    public decimal Amount { get; set; }
    public string? Currency { get; set; }
}

/// <summary>
/// Request model for canceling a payment intent
/// </summary>
public class CancelPaymentIntentRequest
{
    public string PaymentIntentId { get; set; } = string.Empty;
}
