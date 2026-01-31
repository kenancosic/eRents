using eRents.Domain.Models;
using eRents.Domain.Models.Enums;
using eRents.Domain.Shared.Interfaces;
using eRents.Features.PaymentManagement.Interfaces;
using eRents.Features.PaymentManagement.Models;
using eRents.Features.Shared.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Stripe;
using System.Collections.Concurrent;

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
    private readonly IMemoryCache _memoryCache;

    // Thread-safe dictionary to track in-flight payment intent requests per user
    private static readonly ConcurrentDictionary<string, SemaphoreSlim> _userLocks = new();

    public StripePaymentService(
        ERentsContext context,
        ILogger<StripePaymentService> logger,
        IOptions<StripeOptions> stripeOptions,
        ICurrentUserService currentUserService,
        IMemoryCache memoryCache,
        INotificationService? notificationService = null)
    {
        _context = context;
        _logger = logger;
        _stripeOptions = stripeOptions.Value;
        _currentUserService = currentUserService;
        _memoryCache = memoryCache;
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

            // Create idempotency key based on booking details to prevent duplicate intents
            var idempotencyKey = $"booking_intent_{bookingId}_{amountInCents}_{currency.ToLower()}";

            var service = new PaymentIntentService();
            var paymentIntent = await service.CreateAsync(options, new RequestOptions
            {
                IdempotencyKey = idempotencyKey
            });

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
    public async Task<PaymentIntentResponse> CreatePaymentIntentWithAvailabilityCheckAsync(
        int propertyId,
        DateOnly startDate,
        DateOnly? endDate,
        decimal amount,
        string currency = "USD",
        Dictionary<string, string>? metadata = null)
    {
        var currentUserId = _currentUserService?.GetUserIdAsInt();
        if (!currentUserId.HasValue)
            return new PaymentIntentResponse { ErrorMessage = "User not authenticated" };

        var userId = currentUserId.Value;
        var endDateForKey = endDate ?? startDate;
        var cacheKey = $"pi_{userId}_{propertyId}_{startDate:yyyyMMdd}_{endDateForKey:yyyyMMdd}";

        // NOTE: We skip the fast path cache check here because we need to validate
        // the intent status before returning. The locked path handles this properly.
        PaymentIntentResponse? cachedResponse = null;

        var lockKey = $"{userId}:{propertyId}:{startDate:yyyyMMdd}:{endDateForKey:yyyyMMdd}";
        
        // Get or create semaphore for this specific request - use a static lock to prevent race on GetOrAdd itself
        SemaphoreSlim userLock;
        lock (_userLocks)
        {
            if (!_userLocks.TryGetValue(lockKey, out userLock))
            {
                userLock = new SemaphoreSlim(1, 1);
                _userLocks[lockKey] = userLock;
            }
        }

        await userLock.WaitAsync();
        try
        {
            // DOUBLE-CHECK: Another thread may have completed while we were waiting
            if (_memoryCache.TryGetValue(cacheKey, out cachedResponse) && cachedResponse != null)
            {
                // Validate the cached intent is still usable (not cancelled)
                try
                {
                    var stripeService = new PaymentIntentService();
                    var cachedIntent = await stripeService.GetAsync(cachedResponse.PaymentIntentId);
                    if (cachedIntent.Status == "canceled" || cachedIntent.Status == "succeeded")
                    {
                        _logger.LogInformation("Cached intent {PaymentIntentId} is {Status}, removing from cache",
                            cachedResponse.PaymentIntentId, cachedIntent.Status);
                        _memoryCache.Remove(cacheKey);
                        // Fall through to create new intent
                    }
                    else
                    {
                        _logger.LogInformation("Returning cached payment intent {PaymentIntentId} after lock for property {PropertyId}",
                            cachedResponse.PaymentIntentId, propertyId);
                        return cachedResponse;
                    }
                }
                catch
                {
                    // Intent not found or error - remove from cache and create new
                    _memoryCache.Remove(cacheKey);
                }
            }

            return await CreatePaymentIntentWithAvailabilityCheckCore(propertyId, startDate, endDate, amount, currency, metadata, userId, cacheKey);
        }
        finally
        {
            userLock.Release();
            // Clean up the lock entry after a delay to allow queued requests to complete
            _ = Task.Run(async () =>
            {
                await Task.Delay(5000); // Keep lock for 5 seconds to catch stragglers
                lock (_userLocks)
                {
                    if (_userLocks.TryGetValue(lockKey, out var existingLock) && existingLock == userLock)
                    {
                        _userLocks.TryRemove(lockKey, out _);
                    }
                }
            });
        }
    }

    private async Task<PaymentIntentResponse> CreatePaymentIntentWithAvailabilityCheckCore(
        int propertyId, DateOnly startDate, DateOnly? endDate, decimal amount, string currency,
        Dictionary<string, string>? metadata, int userId, string cacheKey)
    {
        try
        {
            _logger.LogInformation("Creating payment intent with availability check for property {PropertyId}, dates {StartDate} to {EndDate}",
                propertyId, startDate, endDate?.ToString() ?? "N/A");

            // Check database for recent pending payment (within last 10 minutes) - in case cache was cleared
            var tenMinutesAgo = DateTime.UtcNow.AddMinutes(-10);
            var existingPayment = await _context.Payments
                .AsNoTracking()
                .Where(p => p.PropertyId == propertyId)
                .Where(p => p.PaymentStatus == "Pending")
                .Where(p => p.CreatedAt >= tenMinutesAgo)
                .Where(p => p.CreatedBy == userId)
                .OrderByDescending(p => p.CreatedAt)
                .FirstOrDefaultAsync();

            if (existingPayment?.StripePaymentIntentId != null)
            {
                _logger.LogInformation("Found existing pending payment {PaymentId} with intent {PaymentIntentId} for property {PropertyId}",
                    existingPayment.PaymentId, existingPayment.StripePaymentIntentId, propertyId);

                // Retrieve the existing Stripe intent to get client secret
                try
                {
                    var stripeService = new PaymentIntentService();
                    var existingIntent = await stripeService.GetAsync(existingPayment.StripePaymentIntentId);

                    if (existingIntent.Status == "requires_payment_method" || existingIntent.Status == "requires_confirmation")
                    {
                        var existingResponse = new PaymentIntentResponse
                        {
                            PaymentIntentId = existingIntent.Id,
                            ClientSecret = existingIntent.ClientSecret,
                            Status = existingIntent.Status,
                            Amount = existingIntent.Amount,
                            Currency = existingIntent.Currency,
                            Metadata = existingIntent.Metadata?.ToDictionary(kvp => kvp.Key, kvp => kvp.Value) ?? new Dictionary<string, string>()
                        };

                        // Cache it for future requests
                        _memoryCache.Set(cacheKey, existingResponse, TimeSpan.FromMinutes(10));
                        return existingResponse;
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Failed to retrieve existing Stripe intent {PaymentIntentId}, will create new one",
                        existingPayment.StripePaymentIntentId);
                }
            }

            // Validate property exists and get owner info
            var property = await _context.Properties
                .Include(p => p.Owner)
                .FirstOrDefaultAsync(p => p.PropertyId == propertyId);

            if (property == null)
            {
                return new PaymentIntentResponse
                {
                    ErrorMessage = "Property not found"
                };
            }

            // Check availability - validate dates don't overlap with existing bookings or active tenancies
            var bookingEnd = endDate ?? startDate;

            // Check for overlapping bookings (Confirmed or Upcoming only - NOT Pending or Cancelled)
            // Use strict inequality to allow adjacent bookings (e.g., booking ends Apr 2, new starts Apr 3)
            var overlappingBookings = await _context.Bookings
                .AsNoTracking()
                .Where(b => b.PropertyId == propertyId)
                .Where(b => b.Status == BookingStatusEnum.Approved || b.Status == BookingStatusEnum.Upcoming)
                .Where(b => b.StartDate < bookingEnd)
                .Where(b => !b.EndDate.HasValue || b.EndDate.Value > startDate)
                .Select(b => new { b.BookingId, b.StartDate, b.EndDate, b.Status })
                .ToListAsync();

            if (overlappingBookings.Any())
            {
                _logger.LogWarning("Availability check failed for property {PropertyId}. Requested: {StartDate} to {EndDate}. Overlapping bookings: {@Bookings}",
                    propertyId, startDate, bookingEnd, overlappingBookings);
                return new PaymentIntentResponse
                {
                    ErrorMessage = "The selected dates are no longer available. Please choose different dates."
                };
            }

            // Check for active tenancy overlap (use strict inequality like booking check)
            var hasTenantOverlap = await _context.Tenants
                .AsNoTracking()
                .Where(t => t.PropertyId == propertyId)
                .Where(t => t.LeaseStartDate.HasValue)
                .Where(t => t.LeaseStartDate!.Value < bookingEnd)
                .Where(t => !t.LeaseEndDate.HasValue || t.LeaseEndDate!.Value > startDate)
                .AnyAsync();

            if (hasTenantOverlap)
            {
                return new PaymentIntentResponse
                {
                    ErrorMessage = "The property is not available for the selected dates due to an active tenancy."
                };
            }

            // Mobile-only restriction: owners cannot book their own properties
            if (_currentUserService?.IsDesktop != true && property.OwnerId == userId)
            {
                return new PaymentIntentResponse
                {
                    ErrorMessage = "Owners cannot book their own properties."
                };
            }

            // Convert amount to cents
            var amountInCents = (long)(amount * 100);

            // Prepare metadata with booking details for later use
            var intentMetadata = metadata ?? new Dictionary<string, string>();
            intentMetadata["property_id"] = propertyId.ToString();
            intentMetadata["user_id"] = userId.ToString();
            intentMetadata["start_date"] = startDate.ToString("yyyy-MM-dd");
            intentMetadata["end_date"] = endDate?.ToString("yyyy-MM-dd") ?? startDate.ToString("yyyy-MM-dd");
            intentMetadata["amount"] = amount.ToString("F2");
            intentMetadata["currency"] = currency;
            intentMetadata["booking_pending"] = "true";

            // Calculate platform fee
            var platformFee = (long)(amountInCents * (_stripeOptions.PlatformFeePercentage / 100));

            // Count cancelled attempts to allow retries after user cancels payment
            // This ensures idempotency key is unique after cancellation but same for rapid duplicate clicks
            var cancelledCount = await _context.Payments
                .AsNoTracking()
                .CountAsync(p => p.PropertyId == propertyId 
                    && p.CreatedBy == userId 
                    && p.PaymentStatus == "Cancelled"
                    && p.CreatedAt >= DateTime.UtcNow.AddHours(-24));

            // Create idempotency key based on booking details to prevent duplicate intents
            var endDateForKey = endDate ?? startDate;
            var idempotencyKey = $"booking_intent_{propertyId}_{userId}_{startDate:yyyyMMdd}_{endDateForKey:yyyyMMdd}_v{cancelledCount}";

            // Create payment intent options
            var options = new PaymentIntentCreateOptions
            {
                Amount = amountInCents,
                Currency = currency.ToLower(),
                Metadata = intentMetadata,
                Description = $"Payment for property #{propertyId} - {startDate:yyyy-MM-dd}",
                
                // If property owner has connected account, use transfers
                TransferData = property.Owner?.StripeAccountId != null
                    ? new PaymentIntentTransferDataOptions
                    {
                        Destination = property.Owner.StripeAccountId,
                        Amount = amountInCents - platformFee
                    }
                    : null,
                
                AutomaticPaymentMethods = new PaymentIntentAutomaticPaymentMethodsOptions
                {
                    Enabled = true
                }
            };

            var service = new PaymentIntentService();
            var paymentIntent = await service.CreateAsync(options, new RequestOptions
            {
                IdempotencyKey = idempotencyKey
            });

            _logger.LogInformation("Created Stripe payment intent {PaymentIntentId} for property {PropertyId} (booking pending)",
                paymentIntent.Id, propertyId);

            // Create a temporary payment record (without booking yet)
            var payment = new Payment
            {
                PropertyId = propertyId,
                Amount = amount,
                Currency = currency,
                PaymentMethod = "Stripe",
                PaymentStatus = "Pending",
                StripePaymentIntentId = paymentIntent.Id,
                PaymentReference = paymentIntent.Id,
                PaymentType = "BookingPayment",
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow,
                CreatedBy = userId,
                ModifiedBy = userId
            };

            _context.Payments.Add(payment);
            await _context.SaveChangesAsync();

            var response = new PaymentIntentResponse
            {
                PaymentIntentId = paymentIntent.Id,
                ClientSecret = paymentIntent.ClientSecret,
                Status = paymentIntent.Status,
                Amount = paymentIntent.Amount,
                Currency = paymentIntent.Currency,
                Metadata = intentMetadata
            };

            // Cache the response for 10 minutes to prevent duplicate intent creation
            _memoryCache.Set(cacheKey, response, TimeSpan.FromMinutes(10));

            return response;
        }
        catch (StripeException ex)
        {
            _logger.LogError(ex, "Stripe error creating payment intent with check for property {PropertyId}: {Message}",
                propertyId, ex.Message);
            
            return new PaymentIntentResponse
            {
                ErrorMessage = $"Payment processing error: {ex.StripeError?.Message ?? ex.Message}"
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating payment intent with check for property {PropertyId}", propertyId);
            
            return new PaymentIntentResponse
            {
                ErrorMessage = "An unexpected error occurred while processing payment"
            };
        }
    }

    /// <inheritdoc/>
    public async Task<BookingAfterPaymentResponse> ConfirmBookingAfterPaymentAsync(
        string paymentIntentId,
        int propertyId,
        DateOnly startDate,
        DateOnly? endDate,
        decimal amount,
        string currency = "USD")
    {
        try
        {
            _logger.LogInformation("Confirming booking after payment for intent {PaymentIntentId}", paymentIntentId);

            // Get current user ID
            var currentUserId = _currentUserService?.GetUserIdAsInt();
            if (!currentUserId.HasValue)
            {
                return new BookingAfterPaymentResponse
                {
                    Success = false,
                    ErrorMessage = "User not authenticated"
                };
            }

            // Find the payment record
            var payment = await _context.Payments
                .FirstOrDefaultAsync(p => p.StripePaymentIntentId == paymentIntentId);

            if (payment == null)
            {
                return new BookingAfterPaymentResponse
                {
                    Success = false,
                    ErrorMessage = "Payment record not found"
                };
            }

            // Idempotency: Check if booking already created for this payment
            if (payment.BookingId.HasValue)
            {
                var existingBooking = await _context.Bookings
                    .FirstOrDefaultAsync(b => b.BookingId == payment.BookingId.Value);

                if (existingBooking != null)
                {
                    _logger.LogInformation("Booking {BookingId} already exists for payment intent {PaymentIntentId} - returning existing",
                        existingBooking.BookingId, paymentIntentId);

                    return new BookingAfterPaymentResponse
                    {
                        Success = true,
                        BookingId = existingBooking.BookingId,
                        PaymentId = payment.PaymentId,
                        Status = existingBooking.Status.ToString(),
                        WasAlreadyCreated = true
                    };
                }
            }

            // Verify payment is completed
            if (payment.PaymentStatus != "Completed")
            {
                // Check with Stripe if payment actually succeeded
                var service = new PaymentIntentService();
                var intent = await service.GetAsync(paymentIntentId);

                if (intent.Status != "succeeded")
                {
                    return new BookingAfterPaymentResponse
                    {
                        Success = false,
                        ErrorMessage = $"Payment not completed. Status: {intent.Status}"
                    };
                }

                // Update payment status
                payment.PaymentStatus = "Completed";
                payment.StripeChargeId = intent.LatestChargeId;
                payment.UpdatedAt = DateTime.UtcNow;
            }

            // Final availability check before creating booking
            var bookingEnd = endDate ?? startDate;

            var hasBookingOverlap = await _context.Bookings
                .AsNoTracking()
                .Where(b => b.PropertyId == propertyId)
                .Where(b => b.Status == BookingStatusEnum.Approved || b.Status == BookingStatusEnum.Upcoming)
                .Where(b => b.StartDate < bookingEnd)
                .Where(b => !b.EndDate.HasValue || b.EndDate.Value > startDate)
                .AnyAsync();

            if (hasBookingOverlap)
            {
                // Refund the payment since dates became unavailable
                _logger.LogWarning("Dates became unavailable after payment for intent {PaymentIntentId} - initiating refund",
                    paymentIntentId);

                try
                {
                    await ProcessRefundAsync(payment.PaymentId, amount, "Dates became unavailable after payment");
                }
                catch (Exception refundEx)
                {
                    _logger.LogError(refundEx, "Failed to refund payment {PaymentId} for unavailable dates", payment.PaymentId);
                }

                return new BookingAfterPaymentResponse
                {
                    Success = false,
                    ErrorMessage = "The selected dates are no longer available. Your payment has been refunded."
                };
            }

            // Create the booking
            var booking = new Booking
            {
                PropertyId = propertyId,
                UserId = currentUserId.Value,
                StartDate = startDate,
                EndDate = endDate,
                TotalPrice = amount,
                Status = BookingStatusEnum.Upcoming,
                PaymentMethod = "Stripe",
                PaymentStatus = "Completed",
                Currency = currency,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow,
                CreatedBy = currentUserId.Value,
                ModifiedBy = currentUserId.Value
            };

            _context.Bookings.Add(booking);
            await _context.SaveChangesAsync();

            // Link payment to booking
            payment.BookingId = booking.BookingId;
            payment.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            _logger.LogInformation("Created booking {BookingId} for payment intent {PaymentIntentId}",
                booking.BookingId, paymentIntentId);

            // Send notifications
            if (_notificationService != null)
            {
                try
                {
                    var property = await _context.Properties
                        .FirstOrDefaultAsync(p => p.PropertyId == propertyId);

                    var propertyName = property?.Name ?? "your property";

                    // Notify tenant
                    await _notificationService.CreatePaymentNotificationAsync(
                        currentUserId.Value,
                        payment.PaymentId,
                        "Booking Confirmed",
                        $"Your booking for {propertyName} on {startDate:MMM dd, yyyy} has been confirmed and paid.");

                    // Notify landlord
                    if (property != null)
                    {
                        await _notificationService.CreatePaymentNotificationAsync(
                            property.OwnerId,
                            payment.PaymentId,
                            "New Booking Received",
                            $"New paid booking for {propertyName} starting {startDate:MMM dd, yyyy}.");
                    }
                }
                catch (Exception notifyEx)
                {
                    _logger.LogError(notifyEx, "Failed to send notifications for booking {BookingId}", booking.BookingId);
                }
            }

            return new BookingAfterPaymentResponse
            {
                Success = true,
                BookingId = booking.BookingId,
                PaymentId = payment.PaymentId,
                Status = booking.Status.ToString(),
                WasAlreadyCreated = false
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error confirming booking after payment for intent {PaymentIntentId}", paymentIntentId);
            
            return new BookingAfterPaymentResponse
            {
                Success = false,
                ErrorMessage = "Failed to create booking after payment. Please contact support."
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

                // Invalidate the memory cache for this property/user combination
                // This ensures the next request creates a fresh payment intent
                var cacheKey = $"payment_intent_{payment.PropertyId}_{payment.CreatedBy}";
                _memoryCache.Remove(cacheKey);
                _logger.LogInformation("Invalidated cache for key {CacheKey} after cancellation", cacheKey);
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
                        // Check if this is a payment-first flow (no bookingId in metadata)
                        var isBookingPending = paymentIntent.Metadata?.ContainsKey("booking_pending") == true &&
                                               paymentIntent.Metadata["booking_pending"] == "true";
                        
                        if (isBookingPending && !string.IsNullOrEmpty(paymentIntent.Metadata?["property_id"]))
                        {
                            // Payment-first flow: create booking after payment
                            await HandlePaymentSuccessAndCreateBookingAsync(paymentIntent);
                        }
                        else
                        {
                            // Original flow: booking already exists
                            await ConfirmPaymentIntentAsync(paymentIntent.Id);
                        }
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

    /// <summary>
    /// Handles payment success for payment-first flow by creating the booking.
    /// Called from webhook when payment_intent.succeeds for pending bookings.
    /// </summary>
    private async Task HandlePaymentSuccessAndCreateBookingAsync(PaymentIntent paymentIntent)
    {
        try
        {
            _logger.LogInformation("Handling payment success and creating booking for intent {PaymentIntentId}", paymentIntent.Id);

            // Extract metadata
            var metadata = paymentIntent.Metadata;
            if (metadata == null || 
                !metadata.TryGetValue("property_id", out var propertyIdStr) ||
                !metadata.TryGetValue("start_date", out var startDateStr) ||
                !metadata.TryGetValue("user_id", out var userIdStr))
            {
                _logger.LogError("Missing required metadata in payment intent {PaymentIntentId}", paymentIntent.Id);
                return;
            }

            if (!int.TryParse(propertyIdStr, out var propertyId) ||
                !int.TryParse(userIdStr, out var userId) ||
                !DateOnly.TryParseExact(startDateStr, "yyyy-MM-dd", out var startDate))
            {
                _logger.LogError("Invalid metadata format in payment intent {PaymentIntentId}", paymentIntent.Id);
                return;
            }

            DateOnly? endDate = null;
            if (metadata.TryGetValue("end_date", out var endDateStr) && 
                DateOnly.TryParseExact(endDateStr, "yyyy-MM-dd", out var parsedEndDate))
            {
                endDate = parsedEndDate;
            }

            var amount = decimal.TryParse(metadata["amount"], out var parsedAmount) ? parsedAmount : 0;
            var currency = metadata.TryGetValue("currency", out var curr) ? curr : "USD";

            // Find the payment record
            var payment = await _context.Payments
                .FirstOrDefaultAsync(p => p.StripePaymentIntentId == paymentIntent.Id);

            if (payment == null)
            {
                _logger.LogError("Payment record not found for intent {PaymentIntentId}", paymentIntent.Id);
                return;
            }

            // Idempotency: Check if booking already created
            if (payment.BookingId.HasValue)
            {
                _logger.LogInformation("Booking {BookingId} already exists for intent {PaymentIntentId} - skipping webhook creation",
                    payment.BookingId.Value, paymentIntent.Id);
                return;
            }

            // Update payment status
            payment.PaymentStatus = "Completed";
            payment.StripeChargeId = paymentIntent.LatestChargeId;
            payment.UpdatedAt = DateTime.UtcNow;

            // Final availability check
            var bookingEnd = endDate ?? startDate;
            var hasBookingOverlap = await _context.Bookings
                .AsNoTracking()
                .Where(b => b.PropertyId == propertyId)
                .Where(b => b.Status == BookingStatusEnum.Approved || b.Status == BookingStatusEnum.Upcoming)
                .Where(b => b.StartDate < bookingEnd)
                .Where(b => !b.EndDate.HasValue || b.EndDate.Value > startDate)
                .AnyAsync();

            if (hasBookingOverlap)
            {
                _logger.LogWarning("Dates became unavailable after payment for intent {PaymentIntentId} - initiating refund", paymentIntent.Id);
                
                try
                {
                    await ProcessRefundAsync(payment.PaymentId, amount, "Dates became unavailable after payment");
                }
                catch (Exception refundEx)
                {
                    _logger.LogError(refundEx, "Failed to refund payment {PaymentId} for unavailable dates", payment.PaymentId);
                }
                return;
            }

            // Create the booking
            var booking = new Booking
            {
                PropertyId = propertyId,
                UserId = userId,
                StartDate = startDate,
                EndDate = endDate,
                TotalPrice = amount,
                Status = BookingStatusEnum.Upcoming,
                PaymentMethod = "Stripe",
                PaymentStatus = "Completed",
                Currency = currency,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow,
                CreatedBy = userId,
                ModifiedBy = userId
            };

            _context.Bookings.Add(booking);
            await _context.SaveChangesAsync();

            // Link payment to booking
            payment.BookingId = booking.BookingId;
            await _context.SaveChangesAsync();

            _logger.LogInformation("Created booking {BookingId} via webhook for intent {PaymentIntentId}",
                booking.BookingId, paymentIntent.Id);

            // Send notifications
            if (_notificationService != null)
            {
                try
                {
                    var property = await _context.Properties
                        .FirstOrDefaultAsync(p => p.PropertyId == propertyId);

                    var propertyName = property?.Name ?? "your property";

                    // Notify tenant
                    await _notificationService.CreatePaymentNotificationAsync(
                        userId,
                        payment.PaymentId,
                        "Booking Confirmed",
                        $"Your booking for {propertyName} on {startDate:MMM dd, yyyy} has been confirmed and paid.");

                    // Notify landlord
                    if (property != null)
                    {
                        await _notificationService.CreatePaymentNotificationAsync(
                            property.OwnerId,
                            payment.PaymentId,
                            "New Booking Received",
                            $"New paid booking for {propertyName} starting {startDate:MMM dd, yyyy}.");
                    }
                }
                catch (Exception notifyEx)
                {
                    _logger.LogError(notifyEx, "Failed to send notifications for webhook booking {BookingId}", booking.BookingId);
                }
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error handling payment success and creating booking for intent {PaymentIntentId}", paymentIntent.Id);
        }
    }
}
