using eRents.Features.PaymentManagement.Models;

namespace eRents.Features.PaymentManagement.Interfaces;

/// <summary>
/// Service interface for Stripe payment processing operations
/// </summary>
public interface IStripePaymentService
{
    /// <summary>
    /// Creates a payment intent for a booking
    /// </summary>
    /// <param name="bookingId">The booking ID to create payment for</param>
    /// <param name="amount">Payment amount</param>
    /// <param name="currency">Currency code (default: USD)</param>
    /// <param name="metadata">Optional metadata to attach to the payment intent</param>
    /// <returns>Payment intent details including client secret</returns>
    Task<PaymentIntentResponse> CreatePaymentIntentAsync(
        int bookingId, 
        decimal amount, 
        string currency = "USD",
        Dictionary<string, string>? metadata = null);
    
    /// <summary>
    /// Creates a payment intent for an existing pending invoice payment
    /// </summary>
    /// <param name="paymentId">The existing payment ID (invoice) to create intent for</param>
    /// <param name="amount">Payment amount</param>
    /// <param name="currency">Currency code (default: USD)</param>
    /// <returns>Payment intent details including client secret</returns>
    Task<PaymentIntentResponse> CreatePaymentIntentForInvoiceAsync(
        int paymentId,
        decimal amount,
        string currency = "USD");
    
    /// <summary>
    /// Confirms a payment intent (typically called from webhook)
    /// </summary>
    /// <param name="paymentIntentId">The payment intent ID</param>
    /// <returns>True if confirmation successful</returns>
    Task<bool> ConfirmPaymentIntentAsync(string paymentIntentId);
    
    /// <summary>
    /// Processes a refund for a payment
    /// </summary>
    /// <param name="paymentId">The payment ID to refund</param>
    /// <param name="amount">Amount to refund (null for full refund)</param>
    /// <param name="reason">Reason for refund</param>
    /// <returns>Refund details</returns>
    Task<RefundResponse> ProcessRefundAsync(int paymentId, decimal? amount = null, string? reason = null);
    
    /// <summary>
    /// Retrieves payment intent details
    /// </summary>
    /// <param name="paymentIntentId">The payment intent ID</param>
    /// <returns>Payment intent details</returns>
    Task<PaymentIntentResponse> GetPaymentIntentAsync(string paymentIntentId);
    
    /// <summary>
    /// Cancels a payment intent
    /// </summary>
    /// <param name="paymentIntentId">The payment intent ID to cancel</param>
    /// <returns>True if cancellation successful</returns>
    Task<bool> CancelPaymentIntentAsync(string paymentIntentId);
    
    /// <summary>
    /// Handles webhook events from Stripe
    /// </summary>
    /// <param name="json">Raw JSON payload from webhook</param>
    /// <param name="signature">Stripe signature header</param>
    /// <returns>True if event processed successfully</returns>
    Task<bool> HandleWebhookEventAsync(string json, string signature);

    /// <summary>
    /// Creates a payment intent with availability check but WITHOUT creating a booking.
    /// Booking is created later after successful payment (via webhook or client confirmation).
    /// </summary>
    /// <param name="propertyId">The property being booked</param>
    /// <param name="startDate">Booking start date</param>
    /// <param name="endDate">Booking end date (optional)</param>
    /// <param name="amount">Payment amount</param>
    /// <param name="currency">Currency code (default: USD)</param>
    /// <param name="metadata">Optional metadata</param>
    /// <returns>Payment intent details including client secret</returns>
    Task<PaymentIntentResponse> CreatePaymentIntentWithAvailabilityCheckAsync(
        int propertyId,
        DateOnly startDate,
        DateOnly? endDate,
        decimal amount,
        string currency = "USD",
        Dictionary<string, string>? metadata = null);

    /// <summary>
    /// Confirms a booking after successful payment.
    /// Creates the booking record and links it to the payment.
    /// Idempotent - safe to call multiple times (returns existing booking if already created).
    /// </summary>
    /// <param name="paymentIntentId">The Stripe payment intent ID</param>
    /// <param name="propertyId">The property being booked</param>
    /// <param name="startDate">Booking start date</param>
    /// <param name="endDate">Booking end date</param>
    /// <param name="amount">Payment amount</param>
    /// <param name="currency">Currency code</param>
    /// <returns>Booking response with booking details</returns>
    Task<BookingAfterPaymentResponse> ConfirmBookingAfterPaymentAsync(
        string paymentIntentId,
        int propertyId,
        DateOnly startDate,
        DateOnly? endDate,
        decimal amount,
        string currency = "USD");
}
