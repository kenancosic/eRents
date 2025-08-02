using eRents.Features.FinancialManagement.DTOs;
using eRents.Features.Shared.DTOs;

namespace eRents.Features.FinancialManagement.Services;

/// <summary>
/// Interface for Payment entity operations
/// Supports dependency injection and testing patterns
/// </summary>
public interface IPaymentService
{
    #region Public Payment Operations

    /// <summary>
    /// Get payments for current user with basic filtering
    /// </summary>
    Task<PagedResponse<PaymentResponse>> GetPaymentsAsync(PaymentSearchObject search);

    /// <summary>
    /// Get payment by ID with authorization check
    /// </summary>
    Task<PaymentResponse?> GetPaymentByIdAsync(int paymentId);

    /// <summary>
    /// Process a payment for a booking - creates database record and processes via PayPal
    /// </summary>
    Task<PaymentResponse> ProcessPaymentAsync(PaymentRequest request);

    /// <summary>
    /// Execute/capture a PayPal payment and update database record
    /// </summary>
    Task<PaymentResponse> ExecutePaymentAsync(string paymentReference, ExecutePaymentRequest request);

    /// <summary>
    /// Create a standalone PayPal payment without booking context
    /// </summary>
    Task<PaymentResponse> CreatePaymentAsync(decimal amount, string currency, string returnUrl, string cancelUrl);

    /// <summary>
    /// Get payment status from database first, fallback to PayPal
    /// </summary>
    Task<PaymentResponse?> GetPaymentStatusAsync(int paymentId);

    /// <summary>
    /// Process refund for a payment using RefundRequest DTO
    /// </summary>
    Task<PaymentResponse> ProcessRefundAsync(RefundRequest request);

    /// <summary>
    /// Process refund for a payment
    /// </summary>
    Task<PaymentResponse> ProcessRefundAsync(int paymentId, decimal refundAmount, string reason);

    /// <summary>
    /// Get payments for a specific user (admin/landlord functionality)
    /// </summary>
    Task<PagedResponse<PaymentResponse>> GetUserPaymentsAsync(int userId, PaymentSearchObject search);

    /// <summary>
    /// Update payment status in database
    /// </summary>
    Task<PaymentResponse> UpdatePaymentStatusAsync(int paymentId, UpdatePaymentStatusRequest request);

    /// <summary>
    /// Get payment by PayPal reference
    /// </summary>
    Task<PaymentResponse?> GetPaymentByReferenceAsync(string paymentReference);

    /// <summary>
    /// Get all payments for a specific booking
    /// </summary>
    Task<PagedResponse<PaymentResponse>> GetPaymentsByBookingAsync(int bookingId, PaymentSearchObject search);

    #endregion
} 
