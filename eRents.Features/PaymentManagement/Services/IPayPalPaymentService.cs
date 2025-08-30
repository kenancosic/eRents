using System.Threading.Tasks;
using eRents.Features.PaymentManagement.Models;

namespace eRents.Features.PaymentManagement.Services
{
    public interface IPayPalPaymentService
    {
        /// <summary>
        /// Processes a payment for a booking
        /// </summary>
        /// <param name="bookingId">The ID of the booking to process payment for</param>
        /// <param name="amount">The amount to charge</param>
        /// <param name="currency">The currency code (e.g., "USD")</param>
        /// <param name="description">Description of the payment</param>
        /// <returns>Payment ID from PayPal</returns>
        Task<string> ProcessPaymentAsync(int bookingId, decimal amount, string currency, string description);
        
        /// <summary>
        /// Processes a refund for a payment
        /// </summary>
        /// <param name="paymentId">The PayPal payment ID to refund</param>
        /// <param name="amount">The amount to refund</param>
        /// <param name="currency">The currency code (e.g., "USD")</param>
        /// <param name="reason">Reason for the refund</param>
        /// <returns>Refund ID from PayPal</returns>
        Task<string> ProcessRefundAsync(string paymentId, decimal amount, string currency, string reason);
        
        /// <summary>
        /// Gets an access token for PayPal API calls
        /// </summary>
        /// <returns>Access token string</returns>
        Task<string> GetAccessTokenAsync();

        /// <summary>
        /// Creates a PayPal order for a booking and returns an approval URL.
        /// </summary>
        /// <param name="request">The details of the order to create.</param>
        /// <returns>A response containing the order ID and approval URL.</returns>
        Task<CreateOrderResponse> CreateOrderAsync(CreateOrderRequest request);

        /// <summary>
        /// Captures a payment for a previously created and approved PayPal order.
        /// </summary>
        /// <param name="orderId">The ID of the order to capture.</param>
        /// <returns>Details of the captured payment.</returns>
        Task<CaptureOrderResponse> CaptureOrderAsync(string orderId);
    }
}
