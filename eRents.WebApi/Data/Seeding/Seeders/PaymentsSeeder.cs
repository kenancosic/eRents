using System;
using System.Linq;
using System.Threading.Tasks;
using eRents.Domain.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace eRents.WebApi.Data.Seeding.Seeders
{
    /// <summary>
    /// Adds historical subscription payments and one refund record to exercise payment flows and refund linkage.
    /// Depends on Bookings and Subscriptions being present.
    /// </summary>
    public class PaymentsSeeder : IDataSeeder
    {
        public int Order => 52; // After Reviews(50) or immediately after Subscriptions(45); ok to be 52
        public string Name => nameof(PaymentsSeeder);

        public async Task SeedAsync(ERentsContext context, ILogger logger, bool forceSeed = false)
        {
            logger?.LogInformation("[{Seeder}] Starting...", Name);

            if (forceSeed)
            {
                // Only clear the synthetic records we add: those with PaymentType = 'SubscriptionPayment' or 'Refund'
                await context.Payments
                    .Where(p => p.PaymentType == "SubscriptionPayment" || p.PaymentType == "Refund")
                    .ExecuteDeleteAsync();
            }

            // If a refund already exists, assume we've run before and keep idempotency
            bool anyRefund = await context.Payments.AnyAsync(p => p.PaymentType == "Refund");
            if (anyRefund && !forceSeed)
            {
                logger?.LogInformation("[{Seeder}] Skipped (refund already present)", Name);
                return;
            }

            // Pick an active subscription if available
            var sub = await context.Subscriptions
                .Include(s => s.Tenant).ThenInclude(t => t.User)
                .Include(s => s.Property).ThenInclude(p => p.Owner)
                .Include(s => s.Booking)
                .AsNoTracking()
                .OrderBy(s => s.SubscriptionId)
                .FirstOrDefaultAsync();

            if (sub == null)
            {
                logger?.LogInformation("[{Seeder}] No subscriptions found; skipping payments seeding.", Name);
                return;
            }

            // Create a completed subscription payment if not present
            var hasSubPayment = await context.Payments.AnyAsync(p => p.SubscriptionId == sub.SubscriptionId);
            Payment? completedPayment = null;

            if (!hasSubPayment || forceSeed)
            {
                var paymentIntentId = $"pi_{Guid.NewGuid().ToString("N").Substring(0, 24)}";
                var chargeId = $"ch_{Guid.NewGuid().ToString("N").Substring(0, 24)}";
                
                completedPayment = new Payment
                {
                    TenantId = sub.TenantId,
                    PropertyId = sub.PropertyId,
                    BookingId = sub.BookingId,
                    SubscriptionId = sub.SubscriptionId,
                    Amount = sub.MonthlyAmount,
                    Currency = sub.Currency,
                    PaymentMethod = "Stripe",
                    PaymentStatus = "Completed",
                    PaymentReference = paymentIntentId,
                    StripePaymentIntentId = paymentIntentId,
                    StripeChargeId = chargeId,
                    PaymentType = "SubscriptionPayment"
                };

                await context.Payments.AddAsync(completedPayment);
                await context.SaveChangesAsync();
            }
            else
            {
                completedPayment = await context.Payments
                    .OrderByDescending(p => p.PaymentId)
                    .FirstOrDefaultAsync(p => p.SubscriptionId == sub.SubscriptionId);
            }

            if (completedPayment == null)
            {
                logger?.LogInformation("[{Seeder}] Could not determine a completed subscription payment to refund; aborting.", Name);
                return;
            }

            // Create a refund for the completed payment (partial refund to be realistic)
            var refundExists = await context.Payments.AnyAsync(p => p.OriginalPaymentId == completedPayment.PaymentId);
            if (!refundExists || forceSeed)
            {
                var refundId = $"re_{Guid.NewGuid().ToString("N").Substring(0, 24)}";
                
                var refund = new Payment
                {
                    TenantId = completedPayment.TenantId,
                    PropertyId = completedPayment.PropertyId,
                    BookingId = completedPayment.BookingId,
                    SubscriptionId = completedPayment.SubscriptionId,
                    Amount = Math.Round(completedPayment.Amount * 0.25m, 2),
                    Currency = completedPayment.Currency,
                    PaymentMethod = "Stripe",
                    PaymentStatus = "Completed",
                    PaymentReference = refundId,
                    StripeChargeId = refundId,
                    RefundReason = "Partial refund due to maintenance inconvenience",
                    PaymentType = "Refund",
                    OriginalPaymentId = completedPayment.PaymentId
                };

                await context.Payments.AddAsync(refund);
                await context.SaveChangesAsync();
                logger?.LogInformation("[{Seeder}] Done. Added subscription payment and refund for subscription {SubscriptionId}.", Name, sub.SubscriptionId);
            }
            else
            {
                logger?.LogInformation("[{Seeder}] Refund already exists for the identified payment; nothing to add.", Name);
            }
        }
    }
}
