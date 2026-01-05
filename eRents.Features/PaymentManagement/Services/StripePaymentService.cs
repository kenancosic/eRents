using eRents.Domain.Models;
using eRents.Domain.Models.Enums;
using eRents.Domain.Shared.Interfaces;
using eRents.Features.PaymentManagement.Interfaces;
using eRents.Features.PaymentManagement.Models;
using eRents.Features.Shared.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Stripe;

namespace eRents.Features.PaymentManagement.Services;

/// <summary>
/// Service for Stripe payment processing operations
/// </summary>
public class StripePaymentService : IStripePaymentService
{
    private readonly ERentsContext _context;
    private readonly ILogger<StripePaymentService> _logger;
    private readonly StripeOptions _stripeOptions;
    private readonly ICurrentUserService _currentUserService;
    private readonly INotificationService? _notificationService;

    public StripePaymentService(
        ERentsContext context,
        ILogger<StripePaymentService> logger,
        IOptions<StripeOptions> stripeOptions,
        ICurrentUserService currentUserService,
        INotificationService? notificationService = null)
    {
        _context = context;
        _logger = logger;
        _stripeOptions = stripeOptions.Value;
        _currentUserService = currentUserService;
        _notificationService = notificationService;
    }

    /// <inheritdoc/>
    public async Task<PaymentIntentResponse> CreatePaymentIntentAsync(
        int bookingId,
        decimal amount,
        string currency = "USD",
        Dictionary<string, string>? metadata = null)
    {
        try
        {
            _logger.LogInformation("Creating Stripe payment intent for booking {BookingId}, amount {Amount} {Currency}",
                bookingId, amount, currency);

            // Validate booking exists and user has access
            var booking = await _context.Bookings
                .Include(b => b.Property)
                    .ThenInclude(p => p.Owner)
                .FirstOrDefaultAsync(b => b.BookingId == bookingId);

            if (booking == null)
            {
                return new PaymentIntentResponse
                {
                    ErrorMessage = "Booking not found"
                };
            }

            // IDEMPOTENCY CHECK: Return existing pending payment intent if one exists
            // This prevents multiple payment records being created on frontend retries
            var existingPayment = await _context.Payments
                .FirstOrDefaultAsync(p => p.BookingId == bookingId 
                    && p.PaymentStatus == "Pending" 
                    && p.PaymentType == "BookingPayment"
                    && !string.IsNullOrEmpty(p.StripePaymentIntentId));

            if (existingPayment != null && !string.IsNullOrEmpty(existingPayment.StripePaymentIntentId))
            {
                _logger.LogInformation("Found existing pending payment {PaymentId} for booking {BookingId}, returning existing intent",
                    existingPayment.PaymentId, bookingId);

                try
                {
                    // Fetch the existing payment intent from Stripe to get fresh client secret
                    var stripeService = new PaymentIntentService();
                    var existingIntent = await stripeService.GetAsync(existingPayment.StripePaymentIntentId);

                    // If the existing intent is still valid (not succeeded/cancelled), return it
                    if (existingIntent.Status == "requires_payment_method" || 
                        existingIntent.Status == "requires_confirmation" ||
                        existingIntent.Status == "requires_action")
                    {
                        return new PaymentIntentResponse
                        {
                            PaymentIntentId = existingIntent.Id,
                            ClientSecret = existingIntent.ClientSecret,
                            Status = existingIntent.Status,
                            Amount = existingIntent.Amount,
                            Currency = existingIntent.Currency,
                            Metadata = existingIntent.Metadata
                        };
                    }

                    // If intent already succeeded, mark payment as completed
                    if (existingIntent.Status == "succeeded")
                    {
                        existingPayment.PaymentStatus = "Completed";
                        existingPayment.UpdatedAt = DateTime.UtcNow;
                        await _context.SaveChangesAsync();
                        
                        return new PaymentIntentResponse
                        {
                            PaymentIntentId = existingIntent.Id,
                            Status = "succeeded",
                            ErrorMessage = "Payment already completed"
                        };
                    }
                }
                catch (StripeException ex)
                {
                    _logger.LogWarning(ex, "Could not retrieve existing payment intent {IntentId}, will create new one",
                        existingPayment.StripePaymentIntentId);
                    // Mark old payment as failed and continue to create new one
                    existingPayment.PaymentStatus = "Failed";
                    existingPayment.UpdatedAt = DateTime.UtcNow;
                    await _context.SaveChangesAsync();
                }
            }

            // Convert amount to cents (Stripe uses smallest currency unit)
            var amountInCents = (long)(amount * 100);

            // Prepare metadata
            var intentMetadata = metadata ?? new Dictionary<string, string>();
            intentMetadata["booking_id"] = bookingId.ToString();
            intentMetadata["property_id"] = booking.PropertyId.ToString();
            intentMetadata["user_id"] = booking.UserId.ToString();

            // Calculate platform fee
            var platformFee = (long)(amountInCents * (_stripeOptions.PlatformFeePercentage / 100));

            // Create payment intent options
            var options = new PaymentIntentCreateOptions
            {
                Amount = amountInCents,
                Currency = currency.ToLower(),
                Metadata = intentMetadata,
                Description = $"Payment for booking #{bookingId}",
                
                // If property owner has connected account, use transfers
                TransferData = booking.Property?.Owner?.StripeAccountId != null
                    ? new PaymentIntentTransferDataOptions
                    {
                        Destination = booking.Property.Owner.StripeAccountId,
                        Amount = amountInCents - platformFee // Transfer after platform fee
                    }
                    : null,
                
                // Automatic payment methods
                AutomaticPaymentMethods = new PaymentIntentAutomaticPaymentMethodsOptions
                {
                    Enabled = true
                }
            };

            var service = new PaymentIntentService();
            var paymentIntent = await service.CreateAsync(options);

            _logger.LogInformation("Created Stripe payment intent {PaymentIntentId} for booking {BookingId}",
                paymentIntent.Id, bookingId);

            // Create pending payment record
            var payment = new Domain.Models.Payment
            {
                BookingId = bookingId,
                Amount = amount,
                Currency = currency,
                PaymentMethod = "Stripe",
                PaymentStatus = "Pending",
                StripePaymentIntentId = paymentIntent.Id,
                PaymentReference = paymentIntent.Id,
                PaymentType = "BookingPayment",
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow,
                CreatedBy = int.TryParse(_currentUserService.UserId, out var userId) ? userId : null,
                ModifiedBy = int.TryParse(_currentUserService.UserId, out var modifiedBy) ? modifiedBy : null
            };

            _context.Payments.Add(payment);
            await _context.SaveChangesAsync();

            return new PaymentIntentResponse
            {
                PaymentIntentId = paymentIntent.Id,
                ClientSecret = paymentIntent.ClientSecret,
                Status = paymentIntent.Status,
                Amount = paymentIntent.Amount,
                Currency = paymentIntent.Currency,
                Metadata = intentMetadata
            };
        }
        catch (StripeException ex)
        {
            _logger.LogError(ex, "Stripe error creating payment intent for booking {BookingId}: {Message}",
                bookingId, ex.Message);
            
            return new PaymentIntentResponse
            {
                ErrorMessage = $"Payment processing error: {ex.StripeError?.Message ?? ex.Message}"
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating payment intent for booking {BookingId}", bookingId);
            
            return new PaymentIntentResponse
            {
                ErrorMessage = "An unexpected error occurred while processing payment"
            };
        }
    }

    /// <inheritdoc/>
    public async Task<PaymentIntentResponse> CreatePaymentIntentForInvoiceAsync(
        int paymentId,
        decimal amount,
        string currency = "USD")
    {
        try
        {
            _logger.LogInformation("Creating Stripe payment intent for invoice payment {PaymentId}, amount {Amount} {Currency}",
                paymentId, amount, currency);

            // Validate payment exists and is pending
            var payment = await _context.Payments
                .Include(p => p.Subscription)
                .Include(p => p.Property)
                    .ThenInclude(p => p.Owner)
                .FirstOrDefaultAsync(p => p.PaymentId == paymentId);

            if (payment == null)
            {
                return new PaymentIntentResponse
                {
                    ErrorMessage = "Payment not found"
                };
            }

            if (payment.PaymentStatus != "Pending")
            {
                return new PaymentIntentResponse
                {
                    ErrorMessage = "Payment is not in pending status"
                };
            }

            // Convert amount to cents (Stripe uses smallest currency unit)
            var amountInCents = (long)(amount * 100);

            // Prepare metadata
            var intentMetadata = new Dictionary<string, string>
            {
                ["payment_id"] = paymentId.ToString(),
                ["subscription_id"] = payment.SubscriptionId?.ToString() ?? "0",
                ["property_id"] = payment.PropertyId?.ToString() ?? "0",
                ["payment_type"] = "SubscriptionPayment"
            };

            // Calculate platform fee
            var platformFee = (long)(amountInCents * (_stripeOptions.PlatformFeePercentage / 100));

            // Create payment intent options
            var options = new PaymentIntentCreateOptions
            {
                Amount = amountInCents,
                Currency = currency.ToLower(),
                Metadata = intentMetadata,
                Description = $"Monthly rent payment for subscription #{payment.SubscriptionId}",
                
                // If property owner has connected account, use transfers
                TransferData = payment.Property?.Owner?.StripeAccountId != null
                    ? new PaymentIntentTransferDataOptions
                    {
                        Destination = payment.Property.Owner.StripeAccountId,
                        Amount = amountInCents - platformFee // Transfer after platform fee
                    }
                    : null,
                
                // Automatic payment methods
                AutomaticPaymentMethods = new PaymentIntentAutomaticPaymentMethodsOptions
                {
                    Enabled = true
                }
            };

            var service = new PaymentIntentService();
            var paymentIntent = await service.CreateAsync(options);

            _logger.LogInformation("Created Stripe payment intent {PaymentIntentId} for invoice payment {PaymentId}",
                paymentIntent.Id, paymentId);

            // Update payment record with Stripe payment intent ID
            payment.StripePaymentIntentId = paymentIntent.Id;
            payment.PaymentReference = paymentIntent.Id;
            payment.UpdatedAt = DateTime.UtcNow;
            payment.ModifiedBy = int.TryParse(_currentUserService.UserId, out var modifiedBy) ? modifiedBy : null;
            
            await _context.SaveChangesAsync();

            return new PaymentIntentResponse
            {
                PaymentIntentId = paymentIntent.Id,
                ClientSecret = paymentIntent.ClientSecret,
                Status = paymentIntent.Status,
                Amount = paymentIntent.Amount,
                Currency = paymentIntent.Currency,
                Metadata = intentMetadata
            };
        }
        catch (StripeException ex)
        {
            _logger.LogError(ex, "Stripe error creating payment intent for invoice payment {PaymentId}: {Message}",
                paymentId, ex.Message);
            
            return new PaymentIntentResponse
            {
                ErrorMessage = $"Payment processing error: {ex.StripeError?.Message ?? ex.Message}"
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating payment intent for invoice payment {PaymentId}", paymentId);
            
            return new PaymentIntentResponse
            {
                ErrorMessage = "An unexpected error occurred while processing payment"
            };
        }
    }

    /// <inheritdoc/>
    public async Task<bool> ConfirmPaymentIntentAsync(string paymentIntentId)
    {
        try
        {
            _logger.LogInformation("Confirming payment intent {PaymentIntentId}", paymentIntentId);

            var service = new PaymentIntentService();
            var paymentIntent = await service.GetAsync(paymentIntentId);

            if (paymentIntent.Status == "succeeded")
            {
                // Update payment record
                var payment = await _context.Payments
                    .Include(p => p.Subscription)
                    .FirstOrDefaultAsync(p => p.StripePaymentIntentId == paymentIntentId);

                if (payment != null)
                {
                    payment.PaymentStatus = "Completed";
                    payment.StripeChargeId = paymentIntent.LatestChargeId;
                    payment.UpdatedAt = DateTime.UtcNow;

                    // Update booking status for regular bookings
                    if (payment.BookingId.HasValue)
                    {
                        var booking = await _context.Bookings.FindAsync(payment.BookingId);
                        if (booking != null)
                        {
                            booking.Status = BookingStatusEnum.Active;
                            booking.UpdatedAt = DateTime.UtcNow;
                        }
                    }

                    // Update subscription next payment date for subscription payments
                    if (payment.Subscription != null && payment.PaymentType == "SubscriptionPayment")
                    {
                        payment.Subscription.NextPaymentDate = payment.Subscription.NextPaymentDate.AddMonths(1);
                        payment.Subscription.Status = SubscriptionStatusEnum.Active;
                        payment.Subscription.UpdatedAt = DateTime.UtcNow;
                        
                        _logger.LogInformation("Updated subscription {SubscriptionId} next payment date to {NextPaymentDate}",
                            payment.Subscription.SubscriptionId, payment.Subscription.NextPaymentDate);
                    }

                    await _context.SaveChangesAsync();
                    
                    _logger.LogInformation("Payment intent {PaymentIntentId} confirmed and records updated", paymentIntentId);

                    // Send payment success notification to tenant
                    if (_notificationService != null && payment.BookingId.HasValue)
                    {
                        try
                        {
                            var booking = await _context.Bookings
                                .Include(b => b.Property)
                                .FirstOrDefaultAsync(b => b.BookingId == payment.BookingId);

                            if (booking != null)
                            {
                                var propertyName = booking.Property?.Name ?? "your property";
                                
                                // Notify tenant of successful payment
                                await _notificationService.CreatePaymentNotificationAsync(
                                    booking.UserId,
                                    payment.PaymentId,
                                    "Payment Successful",
                                    $"Your payment of {payment.Currency} {payment.Amount:F2} for {propertyName} has been confirmed. Your booking is now active!");

                                // Notify landlord of received payment
                                if (booking.Property != null)
                                {
                                    await _notificationService.CreatePaymentNotificationAsync(
                                        booking.Property.OwnerId,
                                        payment.PaymentId,
                                        "Payment Received",
                                        $"Payment of {payment.Currency} {payment.Amount:F2} received for {propertyName}.");
                                }
                            }
                        }
                        catch (Exception notifyEx)
                        {
                            _logger.LogError(notifyEx, "Failed to send payment success notifications for payment {PaymentId}", payment.PaymentId);
                        }
                    }
                }

                return true;
            }

            return false;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error confirming payment intent {PaymentIntentId}", paymentIntentId);
            return false;
        }
    }

    /// <inheritdoc/>
    public async Task<RefundResponse> ProcessRefundAsync(int paymentId, decimal? amount = null, string? reason = null)
    {
        try
        {
            _logger.LogInformation("Processing refund for payment {PaymentId}, amount: {Amount}, reason: {Reason}",
                paymentId, amount, reason);

            var payment = await _context.Payments
                .Include(p => p.Booking)
                .FirstOrDefaultAsync(p => p.PaymentId == paymentId);

            if (payment == null)
            {
                return new RefundResponse
                {
                    ErrorMessage = "Payment not found"
                };
            }

            if (string.IsNullOrWhiteSpace(payment.StripeChargeId))
            {
                return new RefundResponse
                {
                    ErrorMessage = "No Stripe charge ID found for this payment"
                };
            }

            // Calculate refund amount
            var refundAmount = amount.HasValue
                ? (long)(amount.Value * 100)
                : (long)(payment.Amount * 100);

            var options = new RefundCreateOptions
            {
                Charge = payment.StripeChargeId,
                Amount = refundAmount,
                Reason = reason switch
                {
                    "duplicate" => "duplicate",
                    "fraudulent" => "fraudulent",
                    _ => "requested_by_customer"
                },
                Metadata = new Dictionary<string, string>
                {
                    { "payment_id", paymentId.ToString() },
                    { "booking_id", payment.BookingId?.ToString() ?? "0" }
                }
            };

            var service = new RefundService();
            var refund = await service.CreateAsync(options);

            // Create refund payment record
            var refundPayment = new Domain.Models.Payment
            {
                BookingId = payment.BookingId,
                OriginalPaymentId = paymentId,
                Amount = -Math.Abs(amount ?? payment.Amount),
                Currency = payment.Currency,
                PaymentMethod = "Stripe",
                PaymentStatus = refund.Status == "succeeded" ? "Completed" : "Pending",
                PaymentReference = refund.Id,
                StripeChargeId = refund.Id,
                RefundReason = reason,
                PaymentType = "Refund",
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow,
                CreatedBy = int.TryParse(_currentUserService.UserId, out var refundUserId) ? refundUserId : null,
                ModifiedBy = int.TryParse(_currentUserService.UserId, out var refundModifiedBy) ? refundModifiedBy : null
            };

            _context.Payments.Add(refundPayment);

            // Update booking status if full refund
            if (!amount.HasValue || amount.Value >= payment.Amount)
            {
                var booking = await _context.Bookings.FindAsync(payment.BookingId);
                if (booking != null)
                {
                    booking.Status = BookingStatusEnum.Cancelled;
                    booking.UpdatedAt = DateTime.UtcNow;
                }
            }

            await _context.SaveChangesAsync();

            _logger.LogInformation("Refund {RefundId} processed for payment {PaymentId}", refund.Id, paymentId);

            return new RefundResponse
            {
                RefundId = refund.Id,
                Amount = refund.Amount,
                Currency = refund.Currency,
                Status = refund.Status,
                Reason = reason
            };
        }
        catch (StripeException ex)
        {
            _logger.LogError(ex, "Stripe error processing refund for payment {PaymentId}: {Message}",
                paymentId, ex.Message);
            
            return new RefundResponse
            {
                ErrorMessage = $"Refund processing error: {ex.StripeError?.Message ?? ex.Message}"
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing refund for payment {PaymentId}", paymentId);
            
            return new RefundResponse
            {
                ErrorMessage = "An unexpected error occurred while processing refund"
            };
        }
    }

    /// <inheritdoc/>
    public async Task<PaymentIntentResponse> GetPaymentIntentAsync(string paymentIntentId)
    {
        try
        {
            var service = new PaymentIntentService();
            var paymentIntent = await service.GetAsync(paymentIntentId);

            return new PaymentIntentResponse
            {
                PaymentIntentId = paymentIntent.Id,
                ClientSecret = paymentIntent.ClientSecret,
                Status = paymentIntent.Status,
                Amount = paymentIntent.Amount,
                Currency = paymentIntent.Currency,
                Metadata = paymentIntent.Metadata
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving payment intent {PaymentIntentId}", paymentIntentId);
            return new PaymentIntentResponse
            {
                ErrorMessage = "Failed to retrieve payment intent"
            };
        }
    }

    /// <inheritdoc/>
    public async Task<bool> CancelPaymentIntentAsync(string paymentIntentId)
    {
        try
        {
            _logger.LogInformation("Cancelling payment intent {PaymentIntentId}", paymentIntentId);

            var service = new PaymentIntentService();
            await service.CancelAsync(paymentIntentId);

            // Update payment record
            var payment = await _context.Payments
                .FirstOrDefaultAsync(p => p.StripePaymentIntentId == paymentIntentId);

            if (payment != null)
            {
                payment.PaymentStatus = "Cancelled";
                payment.UpdatedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();
            }

            _logger.LogInformation("Payment intent {PaymentIntentId} cancelled", paymentIntentId);
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error cancelling payment intent {PaymentIntentId}", paymentIntentId);
            return false;
        }
    }

    /// <inheritdoc/>
    public async Task<bool> HandleWebhookEventAsync(string json, string signature)
    {
        try
        {
            var stripeEvent = EventUtility.ConstructEvent(
                json,
                signature,
                _stripeOptions.WebhookSecret
            );

            _logger.LogInformation("Processing Stripe webhook event: {EventType}", stripeEvent.Type);

            switch (stripeEvent.Type)
            {
                case "payment_intent.succeeded":
                    var paymentIntent = stripeEvent.Data.Object as PaymentIntent;
                    if (paymentIntent != null)
                    {
                        await ConfirmPaymentIntentAsync(paymentIntent.Id);
                    }
                    break;

                case "payment_intent.payment_failed":
                    var failedIntent = stripeEvent.Data.Object as PaymentIntent;
                    if (failedIntent != null)
                    {
                        await HandlePaymentFailureAsync(failedIntent);
                    }
                    break;

                case "charge.refunded":
                    var charge = stripeEvent.Data.Object as Charge;
                    if (charge != null)
                    {
                        await HandleChargeRefundedAsync(charge);
                    }
                    break;

                default:
                    _logger.LogInformation("Unhandled webhook event type: {EventType}", stripeEvent.Type);
                    break;
            }

            return true;
        }
        catch (StripeException ex)
        {
            _logger.LogError(ex, "Stripe webhook signature verification failed");
            return false;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing Stripe webhook");
            return false;
        }
    }

    private async Task HandlePaymentFailureAsync(PaymentIntent paymentIntent)
    {
        var payment = await _context.Payments
            .FirstOrDefaultAsync(p => p.StripePaymentIntentId == paymentIntent.Id);

        if (payment != null)
        {
            payment.PaymentStatus = "Failed";
            payment.UpdatedAt = DateTime.UtcNow;

            var booking = await _context.Bookings
                .Include(b => b.Property)
                .FirstOrDefaultAsync(b => b.BookingId == payment.BookingId);
            
            if (booking != null)
            {
                booking.Status = BookingStatusEnum.Cancelled;
                booking.UpdatedAt = DateTime.UtcNow;
            }

            await _context.SaveChangesAsync();
            
            _logger.LogWarning("Payment failed for intent {PaymentIntentId}", paymentIntent.Id);

            // Send payment failure notification to tenant
            if (_notificationService != null && booking != null)
            {
                try
                {
                    var propertyName = booking.Property?.Name ?? "your property";
                    
                    await _notificationService.CreatePaymentNotificationAsync(
                        booking.UserId,
                        payment.PaymentId,
                        "Payment Failed",
                        $"Your payment for {propertyName} could not be processed. Please try again or use a different payment method.");
                }
                catch (Exception notifyEx)
                {
                    _logger.LogError(notifyEx, "Failed to send payment failure notification for payment {PaymentId}", payment.PaymentId);
                }
            }
        }
    }

    private async Task HandleChargeRefundedAsync(Charge charge)
    {
        var payment = await _context.Payments
            .FirstOrDefaultAsync(p => p.StripeChargeId == charge.Id);

        if (payment != null)
        {
            payment.PaymentStatus = "Refunded";
            payment.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();
            
            _logger.LogInformation("Charge {ChargeId} marked as refunded", charge.Id);
        }
    }
}
