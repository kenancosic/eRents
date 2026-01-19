using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using eRents.Domain.Models;
using eRents.Domain.Models.Enums;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using eRents.Features.PaymentManagement.Models;
using eRents.Features.Core;
using eRents.Features.Shared.Services;
using System.Text;

namespace eRents.Features.PaymentManagement.Services;

public class SubscriptionService : ISubscriptionService
{
    private readonly ERentsContext _context;
    private readonly ICrudService<Payment, PaymentRequest, PaymentResponse, PaymentSearch> _paymentService;
    private readonly ILogger<SubscriptionService> _logger;
    private readonly INotificationService? _notificationService;

    public SubscriptionService(
        ERentsContext context,
        ICrudService<Payment, PaymentRequest, PaymentResponse, PaymentSearch> paymentService,
        ILogger<SubscriptionService> logger,
        INotificationService? notificationService = null)
    {
        _context = context;
        _paymentService = paymentService;
        _logger = logger;
        _notificationService = notificationService;
    }

    public async Task<Subscription> CreateSubscriptionAsync(
        int tenantId, int propertyId, int bookingId, 
        decimal monthlyAmount, DateOnly startDate, DateOnly? endDate)
    {
        // Calculate next payment date (same day next month or specified payment day)
        var nextPaymentDate = startDate.AddMonths(1);
        
        var subscription = new Subscription
        {
            TenantId = tenantId,
            PropertyId = propertyId,
            BookingId = bookingId,
            MonthlyAmount = monthlyAmount,
            Currency = "USD",
            StartDate = startDate,
            EndDate = endDate,
            PaymentDayOfMonth = startDate.Day,
            NextPaymentDate = nextPaymentDate,
            Status = SubscriptionStatusEnum.Active
        };

        _context.Subscriptions.Add(subscription);
        await _context.SaveChangesAsync();
        
        return subscription;
    }

    public async Task<Payment> ProcessMonthlyPaymentAsync(int subscriptionId)
    {
        var subscription = await _context.Subscriptions
            .Include(s => s.Tenant).ThenInclude(t => t.User)
            .Include(s => s.Property).ThenInclude(p => p.Owner)
            .Include(s => s.Booking)
            .FirstOrDefaultAsync(s => s.SubscriptionId == subscriptionId);

        if (subscription == null)
            throw new ArgumentException($"Subscription with ID {subscriptionId} not found.");

        if (subscription.Status != SubscriptionStatusEnum.Active)
            throw new InvalidOperationException("Subscription is not active.");

        // Check if payment is due
        if (subscription.NextPaymentDate > DateOnly.FromDateTime(DateTime.Today))
            throw new InvalidOperationException("Payment is not due yet.");

        // Create pending payment for manual processing
        var pendingPaymentRequest = new PaymentRequest
        {
            TenantId = subscription.TenantId,
            PropertyId = subscription.PropertyId,
            BookingId = subscription.BookingId,
            SubscriptionId = subscription.SubscriptionId,
            Amount = subscription.MonthlyAmount,
            Currency = subscription.Currency,
            PaymentMethod = "Stripe",
            PaymentStatus = "Pending",
            PaymentReference = null, // Will be set when tenant completes payment
            PaymentType = "SubscriptionPayment"
        };

        try
        {
            var pendingPaymentResponse = await _paymentService.CreateAsync(pendingPaymentRequest);
            var pendingPayment = await _context.Payments.FindAsync(pendingPaymentResponse.PaymentId)
                      ?? throw new InvalidOperationException("Failed to retrieve created pending payment entity.");

            _logger.LogInformation("Created pending payment {PaymentId} for subscription {SubscriptionId}. Tenant must complete payment manually.", 
                pendingPayment.PaymentId, subscriptionId);

            return pendingPayment;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to process monthly payment for subscription {SubscriptionId}", subscriptionId);
            
            // Create failed payment record
            var failedPaymentRequest = new PaymentRequest
            {
                TenantId = subscription.TenantId,
                PropertyId = subscription.PropertyId,
                BookingId = subscription.BookingId,
                SubscriptionId = subscription.SubscriptionId,
                Amount = subscription.MonthlyAmount,
                Currency = subscription.Currency,
                PaymentMethod = "Stripe",
                PaymentStatus = "Failed",
                PaymentReference = null,
                PaymentType = "SubscriptionPayment"
            };

            var failedPaymentResponse = await _paymentService.CreateAsync(failedPaymentRequest);
            
            // Fetch the actual Payment entity from database
            var failedPayment = await _context.Payments.FindAsync(failedPaymentResponse.PaymentId);
            if (failedPayment == null)
                throw new InvalidOperationException("Failed to retrieve created failed payment entity.");

            // Update subscription status
            subscription.Status = SubscriptionStatusEnum.PaymentFailed;
            await _context.SaveChangesAsync();

            return failedPayment;
        }
    }

    public async Task<IEnumerable<Subscription>> GetDueSubscriptionsAsync()
    {
        var today = DateOnly.FromDateTime(DateTime.Today);
        return await _context.Subscriptions
            .Where(s => s.Status == SubscriptionStatusEnum.Active && s.NextPaymentDate <= today)
            .ToListAsync();
    }

    public async Task CancelSubscriptionAsync(int subscriptionId)
    {
        var subscription = await _context.Subscriptions.FindAsync(subscriptionId);
        if (subscription != null)
        {
            subscription.Status = SubscriptionStatusEnum.Cancelled;
            await _context.SaveChangesAsync();
        }
    }

    public async Task PauseSubscriptionAsync(int subscriptionId)
    {
        var subscription = await _context.Subscriptions.FindAsync(subscriptionId);
        if (subscription != null)
        {
            subscription.Status = SubscriptionStatusEnum.Paused;
            await _context.SaveChangesAsync();
        }
    }

    public async Task ResumeSubscriptionAsync(int subscriptionId)
    {
        var subscription = await _context.Subscriptions.FindAsync(subscriptionId);
        if (subscription != null)
        {
            subscription.Status = SubscriptionStatusEnum.Active;
            await _context.SaveChangesAsync();
        }
    }

    /// <summary>
    /// Get subscriptions filtered by tenantId and/or status.
    /// </summary>
    public async Task<IEnumerable<Subscription>> GetSubscriptionsAsync(int? tenantId, string? status)
    {
        var query = _context.Subscriptions.AsQueryable();

        if (tenantId.HasValue)
        {
            query = query.Where(s => s.TenantId == tenantId.Value);
        }

        if (!string.IsNullOrEmpty(status) && Enum.TryParse<SubscriptionStatusEnum>(status, ignoreCase: true, out var statusEnum))
        {
            query = query.Where(s => s.Status == statusEnum);
        }

        return await query.ToListAsync();
    }

    /// <summary>
    /// Sends a payment reminder for an existing pending payment.
    /// </summary>
    public async Task<SendInvoiceResponse> SendPaymentReminderAsync(int paymentId)
    {
        var response = new SendInvoiceResponse();

        try
        {
            // Load payment with related entities
            var payment = await _context.Payments
                .Include(p => p.Tenant).ThenInclude(t => t!.User)
                .Include(p => p.Property)
                .FirstOrDefaultAsync(p => p.PaymentId == paymentId);

            if (payment == null)
            {
                response.Success = false;
                response.Message = $"Payment with ID {paymentId} not found.";
                return response;
            }

            if (payment.PaymentStatus != "Pending")
            {
                response.Success = false;
                response.Message = "Can only send reminders for pending payments.";
                return response;
            }

            var tenant = payment.Tenant;
            var tenantUser = tenant?.User;
            var property = payment.Property;

            if (tenantUser == null)
            {
                response.Success = false;
                response.Message = "Tenant user not found.";
                return response;
            }

            response.PaymentId = paymentId;

            // Send notifications
            if (_notificationService != null)
            {
                try
                {
                    var propertyName = property?.Name ?? "your property";
                    
                    var notificationTitle = "Payment Reminder";
                    var notificationMessage = new StringBuilder();
                    notificationMessage.AppendLine($"This is a reminder that you have an outstanding payment of {payment.Currency} {payment.Amount:F2} for {propertyName}.");
                    notificationMessage.AppendLine();
                    notificationMessage.AppendLine("Please complete payment through the app to avoid late fees.");

                    await _notificationService.CreateNotificationWithEmailAsync(
                        tenantUser.UserId,
                        notificationTitle,
                        notificationMessage.ToString(),
                        "payment_reminder",
                        sendEmail: true,
                        referenceId: paymentId
                    );

                    response.NotificationSent = true;
                    response.EmailSent = true;

                    _logger.LogInformation("Sent payment reminder notification and email to tenant {TenantId} ({Email}) for payment {PaymentId}",
                        tenantUser.UserId, tenantUser.Email, paymentId);
                }
                catch (Exception notifyEx)
                {
                    _logger.LogError(notifyEx, "Failed to send payment reminder notifications for payment {PaymentId}", paymentId);
                    response.NotificationSent = false;
                    response.EmailSent = false;
                }
            }
            else
            {
                _logger.LogWarning("NotificationService not available - payment reminder not sent for payment {PaymentId}", paymentId);
            }

            response.Success = true;
            response.Message = "Payment reminder sent successfully.";
            return response;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error sending payment reminder for payment {PaymentId}", paymentId);
            response.Success = false;
            response.Message = $"Error sending payment reminder: {ex.Message}";
            return response;
        }
    }

    /// <summary>
    /// Sends an invoice/payment request notification to the tenant for a subscription.
    /// Creates a pending payment record and sends both in-app notification and email.
    /// </summary>
    public async Task<SendInvoiceResponse> SendInvoiceAsync(int subscriptionId, SendInvoiceRequest request)
    {
        var response = new SendInvoiceResponse();

        try
        {
            // Load subscription with related entities
            var subscription = await _context.Subscriptions
                .Include(s => s.Tenant).ThenInclude(t => t.User)
                .Include(s => s.Property)
                .FirstOrDefaultAsync(s => s.SubscriptionId == subscriptionId);

            if (subscription == null)
            {
                response.Success = false;
                response.Message = $"Subscription with ID {subscriptionId} not found.";
                return response;
            }

            if (subscription.Status != SubscriptionStatusEnum.Active)
            {
                response.Success = false;
                response.Message = "Cannot send invoice for inactive subscription.";
                return response;
            }

            var tenant = subscription.Tenant;
            var tenantUser = tenant?.User;
            var property = subscription.Property;

            if (tenantUser == null)
            {
                response.Success = false;
                response.Message = "Tenant user not found.";
                return response;
            }

            // Use provided amount or fallback to subscription's monthly amount
            var amount = request.Amount > 0 ? request.Amount : subscription.MonthlyAmount;
            var description = request.Description ?? $"Monthly rent for {property?.Name ?? "property"}";
            var dueDate = request.DueDate ?? DateTime.UtcNow.AddDays(7);

            // Create pending payment record
            var pendingPaymentRequest = new PaymentRequest
            {
                TenantId = subscription.TenantId,
                PropertyId = subscription.PropertyId,
                BookingId = subscription.BookingId,
                SubscriptionId = subscription.SubscriptionId,
                Amount = amount,
                Currency = subscription.Currency,
                PaymentMethod = "Stripe",
                PaymentStatus = "Pending",
                PaymentReference = null,
                PaymentType = "SubscriptionPayment"
            };

            var paymentResponse = await _paymentService.CreateAsync(pendingPaymentRequest);
            response.PaymentId = paymentResponse.PaymentId;

            _logger.LogInformation("Created pending payment {PaymentId} for subscription {SubscriptionId} invoice", 
                paymentResponse.PaymentId, subscriptionId);

            // Send notifications
            if (_notificationService != null)
            {
                try
                {
                    var tenantName = $"{tenantUser.FirstName} {tenantUser.LastName}".Trim();
                    var propertyName = property?.Name ?? "your property";
                    
                    // Build notification message
                    var notificationTitle = "Payment Request";
                    var notificationMessage = new StringBuilder();
                    notificationMessage.AppendLine($"Your landlord has requested payment of {subscription.Currency} {amount:F2} for {propertyName}.");
                    notificationMessage.AppendLine();
                    notificationMessage.AppendLine($"Description: {description}");
                    notificationMessage.AppendLine($"Due Date: {dueDate:MMMM dd, yyyy}");
                    notificationMessage.AppendLine();
                    notificationMessage.AppendLine("Please complete payment through the app to avoid late fees.");

                    // Create in-app notification and send email
                    await _notificationService.CreateNotificationWithEmailAsync(
                        tenantUser.UserId,
                        notificationTitle,
                        notificationMessage.ToString(),
                        "payment",
                        sendEmail: true,
                        referenceId: paymentResponse.PaymentId
                    );

                    response.NotificationSent = true;
                    response.EmailSent = true;

                    _logger.LogInformation("Sent invoice notification and email to tenant {TenantId} ({Email}) for subscription {SubscriptionId}",
                        tenantUser.UserId, tenantUser.Email, subscriptionId);
                }
                catch (Exception notifyEx)
                {
                    _logger.LogError(notifyEx, "Failed to send invoice notifications for subscription {SubscriptionId}", subscriptionId);
                    response.NotificationSent = false;
                    response.EmailSent = false;
                }
            }
            else
            {
                _logger.LogWarning("NotificationService not available - invoice created but no notifications sent for subscription {SubscriptionId}", subscriptionId);
            }

            response.Success = true;
            response.Message = "Invoice sent successfully.";
            return response;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error sending invoice for subscription {SubscriptionId}", subscriptionId);
            response.Success = false;
            response.Message = $"Error sending invoice: {ex.Message}";
            return response;
        }
    }
}
