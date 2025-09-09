using System;
using System.Threading;
using System.Threading.Tasks;
using System.Linq;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using eRents.Features.PaymentManagement.Services;

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
                
                // Get subscriptions with payments due
                var dueSubscriptions = await subscriptionService.GetDueSubscriptionsAsync();
                
                _logger.LogInformation("Found {Count} subscriptions with payments due", dueSubscriptions.Count());
                
                // Process each due payment
                foreach (var subscription in dueSubscriptions)
                {
                    try
                    {
                        await subscriptionService.ProcessMonthlyPaymentAsync(subscription.SubscriptionId);
                        _logger.LogInformation("Processed monthly payment for subscription {SubscriptionId}", subscription.SubscriptionId);
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
