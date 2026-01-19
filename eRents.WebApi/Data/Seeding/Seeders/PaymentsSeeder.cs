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

            // Get all active subscriptions to create payment history for each
            var subscriptions = await context.Subscriptions
                .Include(s => s.Tenant).ThenInclude(t => t.User)
                .Include(s => s.Property).ThenInclude(p => p.Owner)
                .Include(s => s.Booking)
                .AsNoTracking()
                .ToListAsync();

            if (!subscriptions.Any())
            {
                logger?.LogInformation("[{Seeder}] No subscriptions found; skipping payments seeding.", Name);
                return;
            }

            var paymentsAdded = 0;
            var now = DateTime.UtcNow;

            foreach (var sub in subscriptions)
            {
                // Check if payments already exist for this subscription
                var existingPaymentCount = await context.Payments.CountAsync(p => p.SubscriptionId == sub.SubscriptionId);
                if (existingPaymentCount >= 3 && !forceSeed)
                {
                    continue; // Already has enough payment history
                }

                var payments = new List<Payment>();

                // Create 3-4 months of payment history for each subscription
                for (int monthsAgo = 3; monthsAgo >= 0; monthsAgo--)
                {
                    var paymentDate = now.AddMonths(-monthsAgo);
                    var paymentIntentId = $"pi_{Guid.NewGuid().ToString("N").Substring(0, 24)}";
                    var chargeId = $"ch_{Guid.NewGuid().ToString("N").Substring(0, 24)}";

                    // Vary payment statuses for realism
                    string status;
                    if (monthsAgo == 0)
                    {
                        status = "Pending"; // Current month is pending
                    }
                    else if (monthsAgo == 2 && sub.SubscriptionId % 2 == 0)
                    {
                        status = "Failed"; // Some subscriptions have a failed payment
                    }
                    else
                    {
                        status = "Completed";
                    }

                    var payment = new Payment
                    {
                        TenantId = sub.TenantId,
                        PropertyId = sub.PropertyId,
                        BookingId = sub.BookingId,
                        SubscriptionId = sub.SubscriptionId,
                        Amount = sub.MonthlyAmount,
                        Currency = sub.Currency,
                        PaymentMethod = monthsAgo % 2 == 0 ? "Stripe" : "CreditCard",
                        PaymentStatus = status,
                        PaymentReference = status == "Completed" ? paymentIntentId : null,
                        StripePaymentIntentId = status == "Completed" ? paymentIntentId : null,
                        StripeChargeId = status == "Completed" ? chargeId : null,
                        PaymentType = "SubscriptionPayment",
                        CreatedAt = paymentDate,
                        UpdatedAt = paymentDate
                    };

                    payments.Add(payment);
                }

                if (payments.Any())
                {
                    await context.Payments.AddRangeAsync(payments);
                    paymentsAdded += payments.Count;
                }
            }

            if (paymentsAdded > 0)
            {
                await context.SaveChangesAsync();
            }

            // Create refund for the first completed payment if not exists
            var firstCompletedPayment = await context.Payments
                .OrderBy(p => p.PaymentId)
                .FirstOrDefaultAsync(p => p.PaymentStatus == "Completed" && p.PaymentType == "SubscriptionPayment");

            if (firstCompletedPayment != null)
            {
                var refundExists = await context.Payments.AnyAsync(p => p.OriginalPaymentId == firstCompletedPayment.PaymentId);
                if (!refundExists || forceSeed)
                {
                    var refundId = $"re_{Guid.NewGuid().ToString("N").Substring(0, 24)}";
                    
                    var refund = new Payment
                    {
                        TenantId = firstCompletedPayment.TenantId,
                        PropertyId = firstCompletedPayment.PropertyId,
                        BookingId = firstCompletedPayment.BookingId,
                        SubscriptionId = firstCompletedPayment.SubscriptionId,
                        Amount = Math.Round(firstCompletedPayment.Amount * 0.25m, 2),
                        Currency = firstCompletedPayment.Currency,
                        PaymentMethod = "Stripe",
                        PaymentStatus = "Completed",
                        PaymentReference = refundId,
                        StripeChargeId = refundId,
                        RefundReason = "Partial refund due to maintenance inconvenience",
                        PaymentType = "Refund",
                        OriginalPaymentId = firstCompletedPayment.PaymentId
                    };

                    await context.Payments.AddAsync(refund);
                    await context.SaveChangesAsync();
                    paymentsAdded++;
                }
            }

            logger?.LogInformation("[{Seeder}] Done. Added {Count} payment records.", Name, paymentsAdded);
        }
    }
}
