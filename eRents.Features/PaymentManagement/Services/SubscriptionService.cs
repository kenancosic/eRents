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

namespace eRents.Features.PaymentManagement.Services;

public class SubscriptionService : ISubscriptionService
{
    private readonly ERentsContext _context;
    private readonly IPayPalPaymentService _payPalService;
    private readonly ICrudService<Payment, PaymentRequest, PaymentResponse, PaymentSearch> _paymentService;
    private readonly ILogger<SubscriptionService> _logger;

    public SubscriptionService(
        ERentsContext context,
        IPayPalPaymentService payPalService,
        ICrudService<Payment, PaymentRequest, PaymentResponse, PaymentSearch> paymentService,
        ILogger<SubscriptionService> logger)
    {
        _context = context;
        _payPalService = payPalService;
        _paymentService = paymentService;
        _logger = logger;
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

        try
        {
            // Pre-check PayPal linkage for both parties to fail fast with clearer reason
            if (subscription.Property?.Owner?.PaypalUserIdentifier == null)
                throw new InvalidOperationException("Property owner does not have a PayPal account linked.");

            if (subscription.Tenant?.User?.PaypalUserIdentifier == null)
                throw new InvalidOperationException("Tenant does not have a PayPal account linked.");

            // Process payment through PayPal
            var paymentReference = await _payPalService.ProcessPaymentAsync(
                subscription.BookingId,
                subscription.MonthlyAmount,
                subscription.Currency,
                $"Monthly rent payment for {subscription.Property.Name}");

            // Create payment record
            var paymentRequest = new PaymentRequest
            {
                TenantId = subscription.TenantId,
                PropertyId = subscription.PropertyId,
                BookingId = subscription.BookingId,
                SubscriptionId = subscription.SubscriptionId,
                Amount = subscription.MonthlyAmount,
                Currency = subscription.Currency,
                PaymentMethod = "PayPal",
                PaymentStatus = "Completed",
                PaymentReference = paymentReference,
                PaymentType = "SubscriptionPayment"
            };

            var paymentResponse = await _paymentService.CreateAsync(paymentRequest);
            
            // Fetch the actual Payment entity from database
            var payment = await _context.Payments.FindAsync(paymentResponse.PaymentId);
            if (payment == null)
                throw new InvalidOperationException("Failed to retrieve created payment entity.");

            // Update subscription for next payment
            subscription.NextPaymentDate = subscription.NextPaymentDate.AddMonths(1);
            
            // Check if subscription has ended
            if (subscription.EndDate.HasValue && subscription.NextPaymentDate > subscription.EndDate.Value)
            {
                subscription.Status = SubscriptionStatusEnum.Completed;
            }

            await _context.SaveChangesAsync();

            return payment;
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
                PaymentMethod = "PayPal",
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
}
