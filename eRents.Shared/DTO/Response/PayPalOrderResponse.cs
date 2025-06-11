namespace eRents.Shared.DTO.Response
{
    /// <summary>
    /// PayPal-specific response for order operations
    /// </summary>
    public class PayPalOrderResponse
    {
        public string Id { get; set; } = string.Empty;
        public string Status { get; set; } = string.Empty;
        public string ApprovalUrl { get; set; } = string.Empty;
        public decimal Amount { get; set; }
        public string Currency { get; set; } = string.Empty;
        public List<PayPalLinkResponse> Links { get; set; } = new();
    }

    /// <summary>
    /// PayPal-specific response for refund operations
    /// </summary>
    public class PayPalRefundResponse
    {
        public string Id { get; set; } = string.Empty;
        public string Status { get; set; } = string.Empty;
        public decimal Amount { get; set; }
        public string Currency { get; set; } = string.Empty;
    }

    /// <summary>
    /// PayPal link object for navigation
    /// </summary>
    public class PayPalLinkResponse
    {
        public string Href { get; set; } = string.Empty;
        public string Rel { get; set; } = string.Empty;
        public string Method { get; set; } = string.Empty;
    }

    /// <summary>
    /// PayPal token response for authentication
    /// </summary>
    public class PayPalTokenResponse
    {
        public string AccessToken { get; set; } = string.Empty;
        public string TokenType { get; set; } = string.Empty;
        public string AppId { get; set; } = string.Empty;
        public int ExpiresIn { get; set; }
    }
} 