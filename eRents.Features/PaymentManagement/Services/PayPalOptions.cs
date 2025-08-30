using System;

namespace eRents.Features.PaymentManagement.Services;

public class PayPalOptions
{
    public string Environment { get; set; } = "Sandbox"; // Sandbox | Live
    public string ClientId { get; set; } = string.Empty;
    public string Secret { get; set; } = string.Empty;
    public string RedirectUri { get; set; } = string.Empty; // e.g. https://localhost:5001/api/PaypalLink/callback
    public string Scopes { get; set; } = "openid profile email";
    public string ApiBaseUrl { get; set; } = string.Empty;

    public string ApiBase => string.IsNullOrEmpty(ApiBaseUrl) ? 
        (string.Equals(Environment, "Live", StringComparison.OrdinalIgnoreCase)
        ? "https://api-m.paypal.com"
        : "https://api-m.sandbox.paypal.com")
        : ApiBaseUrl;

    public string AuthorizeBase => string.Equals(Environment, "Live", StringComparison.OrdinalIgnoreCase)
        ? "https://www.paypal.com"
        : "https://www.sandbox.paypal.com";
}
