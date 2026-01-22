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
    /// Creates subscriptions for active bookings (monthly rentals) if missing.
    /// Derives TenantId from matching tenant record (UserId + PropertyId).
    /// </summary>
    public class SubscriptionsSeeder : IDataSeeder
    {
        public int Order => 45; // after Bookings (40) and before payments/reviews
        public string Name => nameof(SubscriptionsSeeder);

        public async Task SeedAsync(ERentsContext context, ILogger logger, bool forceSeed = false)
        {
            logger?.LogInformation("[{Seeder}] Starting...", Name);

            if (forceSeed)
            {
                await context.Subscriptions.IgnoreQueryFilters().ExecuteDeleteAsync();
            }

            var activeBookings = await context.Bookings
                .AsNoTracking()
                .Where(b => b.Status == BookingStatusEnum.Active)
                .ToListAsync();

            if (activeBookings.Count == 0)
            {
                logger?.LogInformation("[{Seeder}] Skipped (no active bookings)", Name);
                return;
            }

            foreach (var booking in activeBookings)
            {
                var exists = await context.Subscriptions.AnyAsync(s => s.BookingId == booking.BookingId);
                if (exists) continue;

                var tenant = await context.Tenants
                    .AsNoTracking()
                    .FirstOrDefaultAsync(t => t.PropertyId == booking.PropertyId && t.UserId == booking.UserId);
                if (tenant == null) continue;

                var property = await context.Properties.AsNoTracking().FirstOrDefaultAsync(p => p.PropertyId == booking.PropertyId);
                if (property == null) continue;

                // Vary payment day based on property to simulate real contracts (1st, 5th, 10th, 15th)
                var paymentDay = ((property.PropertyId % 4) + 1) * 5; // 5, 10, 15, or 20
                if (paymentDay > 28) paymentDay = 1; // Safety for short months
                
                // Calculate next payment date relative to today
                var today = DateOnly.FromDateTime(DateTime.UtcNow);
                var thisMonthPayment = new DateOnly(today.Year, today.Month, Math.Min(paymentDay, DateTime.DaysInMonth(today.Year, today.Month)));
                var nextPayment = today.Day >= paymentDay 
                    ? thisMonthPayment.AddMonths(1) 
                    : thisMonthPayment;
                
                // Ensure next payment is within subscription period
                if (booking.EndDate.HasValue && nextPayment > booking.EndDate.Value)
                {
                    nextPayment = booking.EndDate.Value;
                }

                var sub = new Subscription
                {
                    TenantId = tenant.TenantId,
                    PropertyId = booking.PropertyId,
                    BookingId = booking.BookingId,
                    MonthlyAmount = property.Price,
                    Currency = property.Currency,
                    StartDate = booking.StartDate,
                    EndDate = booking.EndDate,
                    PaymentDayOfMonth = paymentDay,
                    Status = SubscriptionStatusEnum.Active,
                    NextPaymentDate = nextPayment
                };

                await context.Subscriptions.AddAsync(sub);
            }

            await context.SaveChangesAsync();
            logger?.LogInformation("[{Seeder}] Done. Ensured subscriptions for active bookings.", Name);
        }
    }
}
