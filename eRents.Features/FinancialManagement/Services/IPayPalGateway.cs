using eRents.Features.FinancialManagement.DTOs;

namespace eRents.Features.FinancialManagement.Services
{
    /// <summary>
    /// Pure PayPal gateway interface for external payment processing
    /// Separate from IPaymentService to follow Interface Segregation Principle
    /// </summary>
    public interface IPayPalGateway
    {
        /// <summary>
        /// Creates a PayPal order and returns approval URL
        /// </summary>
        Task<PayPalOrderResponse> CreateOrderAsync(decimal amount, string currency, string returnUrl, string cancelUrl);
        
        /// <summary>
        /// Captures an approved PayPal order
        /// </summary>
        Task<PayPalOrderResponse> CaptureOrderAsync(string orderId);
        
        /// <summary>
        /// Processes a refund for a captured PayPal payment
        /// </summary>
        Task<PayPalRefundResponse> ProcessRefundAsync(string captureId, decimal amount, string currency, string? reason = null);
        
        /// <summary>
        /// Gets the status of a PayPal order
        /// </summary>
        Task<PayPalOrderResponse> GetOrderStatusAsync(string orderId);
    }
} 