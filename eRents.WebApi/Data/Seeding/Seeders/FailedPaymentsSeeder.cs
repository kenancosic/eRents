using System;
using System.Linq;
using System.Threading.Tasks;
using eRents.Domain.Models;
using eRents.Domain.Models.Enums;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace eRents.WebApi.Data.Seeding.Seeders
{
    /// <summary>
    /// Seeds failed payment scenarios to test error handling and retry flows.
    /// Creates payments with Failed status and appropriate error messages.
    /// </summary>
    public class FailedPaymentsSeeder : IDataSeeder
    {
        public int Order => 53; // After PaymentsSeeder (52)
        public string Name => nameof(FailedPaymentsSeeder);

        public async Task SeedAsync(ERentsContext context, ILogger logger, bool forceSeed = false)
        {
            logger?.LogInformation("[{Seeder}] Starting...", Name);

            // Check if failed payments already exist
            var hasFailedPayments = await context.Payments.AnyAsync(p => p.PaymentStatus == "Failed");
            if (!forceSeed && hasFailedPayments)
            {
                logger?.LogInformation("[{Seeder}] Skipped (failed payments already present)", Name);
                return;
            }

            if (forceSeed)
            {
                await context.Payments.Where(p => p.PaymentStatus == "Failed").ExecuteDeleteAsync();
            }

            // Get subscriptions for failed payment scenarios
            var subscriptions = await context.Subscriptions
                .Include(s => s.Tenant)
                .Include(s => s.Property)
                .AsNoTracking()
                .Take(3)
                .ToListAsync();

            // Get some bookings for failed booking payments
            var bookings = await context.Bookings
                .Include(b => b.Property)
                .AsNoTracking()
                .Where(b => b.Status == BookingStatusEnum.Active || b.Status == BookingStatusEnum.Upcoming)
                .Take(3)
                .ToListAsync();

            var failedPayments = new List<Payment>();
            var failureReasons = new[]
            {
                "Card declined - insufficient funds",
                "Card expired",
                "Payment gateway timeout",
                "Invalid card number",
                "Card blocked by issuer",
                "3D Secure authentication failed"
            };

            // Create failed subscription payments
            foreach (var sub in subscriptions)
            {
                var paymentIntentId = $"pi_failed_{Guid.NewGuid().ToString("N").Substring(0, 16)}";
                failedPayments.Add(new Payment
                {
                    TenantId = sub.TenantId,
                    PropertyId = sub.PropertyId,
                    BookingId = sub.BookingId,
                    SubscriptionId = sub.SubscriptionId,
                    Amount = sub.MonthlyAmount,
                    Currency = sub.Currency,
                    PaymentMethod = "Stripe",
                    PaymentStatus = "Failed",
                    PaymentReference = paymentIntentId,
                    StripePaymentIntentId = paymentIntentId,
                    RefundReason = failureReasons[Random.Shared.Next(failureReasons.Length)],
                    PaymentType = "SubscriptionPayment"
                });
            }

            // Create failed booking payments
            foreach (var booking in bookings)
            {
                var paymentIntentId = $"pi_fail_{Guid.NewGuid().ToString("N").Substring(0, 16)}";
                failedPayments.Add(new Payment
                {
                    PropertyId = booking.PropertyId,
                    BookingId = booking.BookingId,
                    Amount = booking.TotalPrice * 0.5m, // Partial payment attempt
                    Currency = booking.Currency,
                    PaymentMethod = Random.Shared.Next(2) == 0 ? "PayPal" : "CreditCard",
                    PaymentStatus = "Failed",
                    PaymentReference = paymentIntentId,
                    RefundReason = failureReasons[Random.Shared.Next(failureReasons.Length)],
                    PaymentType = "BookingPayment"
                });
            }

            if (failedPayments.Count > 0)
            {
                await context.Payments.AddRangeAsync(failedPayments);
                await context.SaveChangesAsync();
            }

            logger?.LogInformation("[{Seeder}] Done. Added {Count} failed payment scenarios.", Name, failedPayments.Count);
        }
    }
}
