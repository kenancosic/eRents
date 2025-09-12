using System;
using System.Threading;
using System.Threading.Tasks;
using System.Linq;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using eRents.Features.PaymentManagement.Services;
using eRents.Shared.Services;
using eRents.Shared.DTOs;
using eRents.Domain.Models;
using Microsoft.EntityFrameworkCore;

namespace eRents.WebApi.Services;

public class MonthlyPaymentBackgroundService : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<MonthlyPaymentBackgroundService> _logger;

    public MonthlyPaymentBackgroundService(
        IServiceProvider serviceProvider,
        ILogger<MonthlyPaymentBackgroundService> logger)
    {
        _serviceProvider = serviceProvider;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                using var scope = _serviceProvider.CreateScope();
                var subscriptionService = scope.ServiceProvider.GetRequiredService<ISubscriptionService>();
                var payPal = scope.ServiceProvider.GetRequiredService<IPayPalPaymentService>();
                var emailService = scope.ServiceProvider.GetRequiredService<IEmailService>();
                var context = scope.ServiceProvider.GetRequiredService<ERentsContext>();
                
                // Get subscriptions with payments due
                var dueSubscriptions = await subscriptionService.GetDueSubscriptionsAsync();
                
                _logger.LogInformation("Found {Count} subscriptions with payments due", dueSubscriptions.Count());
                
                // Process each due payment
                foreach (var subscription in dueSubscriptions)
                {
                    try
                    {
                        var payment = await subscriptionService.ProcessMonthlyPaymentAsync(subscription.SubscriptionId);
                        _logger.LogInformation("Created pending invoice payment {PaymentId} for subscription {SubscriptionId}", payment.PaymentId, subscription.SubscriptionId);

                        // Generate approval URL for email/out-of-app payment
                        var order = await payPal.CreateOrderForPaymentAsync(payment.PaymentId);

                        // Fetch tenant email
                        var tenant = await context.Tenants
                            .Include(t => t.User)
                            .FirstOrDefaultAsync(t => t.TenantId == subscription.TenantId);
                        var tenantEmail = tenant?.User?.Email;

                        if (!string.IsNullOrWhiteSpace(tenantEmail))
                        {
                            var email = new EmailMessage
                            {
                                To = tenantEmail,
                                Subject = $"Invoice for Subscription #{subscription.SubscriptionId}",
                                Body = $"Hello,\n\nYour monthly rent invoice is ready. Amount: {payment.Amount:0.00} {payment.Currency}.\nYou can pay using PayPal with this link: {order.ApprovalUrl}\n\nThank you.\n",
                                IsHtml = false
                            };
                            await emailService.SendEmailNotificationAsync(email, stoppingToken);
                            _logger.LogInformation("Sent invoice email to {Email} for payment {PaymentId}", tenantEmail, payment.PaymentId);
                        }
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "Failed to process payment for subscription {SubscriptionId}", subscription.SubscriptionId);
                        // Continue with other subscriptions even if one fails
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in monthly payment background service");
            }
            
            // Wait for 24 hours before next check
            await Task.Delay(TimeSpan.FromHours(24), stoppingToken);
        }
    }
}
