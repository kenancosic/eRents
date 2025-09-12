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
    /// Adds additional booking scenarios to diversify statuses: Completed and Cancelled.
    /// Depends on Users and Properties baseline existing.
    /// </summary>
    public class BookingsVarietySeeder : IDataSeeder
    {
        public int Order => 41; // Immediately after BookingsSeeder (40)
        public string Name => nameof(BookingsVarietySeeder);

        public async Task SeedAsync(ERentsContext context, ILogger logger, bool forceSeed = false)
        {
            logger?.LogInformation("[{Seeder}] Starting...", Name);

            if (forceSeed)
            {
                // Only delete the extra scenarios we add: Completed/Cancelled without overlapping main seeder ones
                await context.Bookings.Where(b => b.Status == BookingStatusEnum.Completed || b.Status == BookingStatusEnum.Cancelled).ExecuteDeleteAsync();
                await context.Tenants.Where(t => t.LeaseEndDate < DateOnly.FromDateTime(DateTime.Today)).ExecuteDeleteAsync();
            }

            var guest = await context.Users.AsNoTracking().FirstOrDefaultAsync(u => u.Username == "guestuser");
            var owner = await context.Users.AsNoTracking().FirstOrDefaultAsync(u => u.Username == "desktop");
            var property = await context.Properties.AsNoTracking().OrderByDescending(p => p.PropertyId).FirstOrDefaultAsync();
            var anotherProperty = await context.Properties.AsNoTracking().OrderBy(p => p.PropertyId).Skip(1).FirstOrDefaultAsync();

            if (guest == null || owner == null || property == null)
            {
                logger?.LogInformation("[{Seeder}] Prerequisites missing (guest/owner/property)", Name);
                return;
            }

            // Completed booking (historical)
            bool hasCompleted = await context.Bookings.AnyAsync(b => b.UserId == guest.UserId && b.Status == BookingStatusEnum.Completed);
            if (!hasCompleted || forceSeed)
            {
                var start = DateOnly.FromDateTime(DateTime.UtcNow.AddMonths(-6));
                var end = DateOnly.FromDateTime(DateTime.UtcNow.AddMonths(-2));
                var months = 4;
                var completed = new Booking
                {
                    PropertyId = property.PropertyId,
                    UserId = guest.UserId,
                    StartDate = start,
                    EndDate = end,
                    TotalPrice = Math.Max(1m, property.Price) * months,
                    Status = BookingStatusEnum.Completed,
                    PaymentStatus = "Completed",
                    Currency = property.Currency ?? "USD",
                    IsSubscription = false
                };
                await context.Bookings.AddAsync(completed);
                await context.SaveChangesAsync();

                // Create a single payment record for the completed booking
                var payment = new Payment
                {
                    BookingId = completed.BookingId,
                    PropertyId = property.PropertyId,
                    Amount = Math.Max(1m, property.Price) * months,
                    Currency = completed.Currency,
                    PaymentMethod = "CreditCard",
                    PaymentStatus = "Completed",
                    PaymentType = "BookingPayment",
                    PaymentReference = $"BK_{completed.BookingId}_CC"
                };
                await context.Payments.AddAsync(payment);

                // Create a tenant record for history
                var tenancy = new Tenant
                {
                    UserId = guest.UserId,
                    PropertyId = property.PropertyId,
                    LeaseStartDate = start,
                    LeaseEndDate = end,
                    TenantStatus = TenantStatusEnum.LeaseEnded
                };
                await context.Tenants.AddAsync(tenancy);
                await context.SaveChangesAsync();
            }

            // Cancelled future booking
            if (anotherProperty != null)
            {
                bool hasCancelled = await context.Bookings.AnyAsync(b => b.UserId == guest.UserId && b.PropertyId == anotherProperty.PropertyId && b.Status == BookingStatusEnum.Cancelled);
                if (!hasCancelled || forceSeed)
                {
                    var start = DateOnly.FromDateTime(DateTime.UtcNow.AddMonths(2));
                    var cancelled = new Booking
                    {
                        PropertyId = anotherProperty.PropertyId,
                        UserId = guest.UserId,
                        StartDate = start,
                        EndDate = start.AddMonths(1),
                        TotalPrice = Math.Max(1m, anotherProperty.Price),
                        Status = BookingStatusEnum.Cancelled,
                        PaymentStatus = "Refunded",
                        Currency = anotherProperty.Currency ?? "USD",
                        IsSubscription = false
                    };
                    await context.Bookings.AddAsync(cancelled);
                    await context.SaveChangesAsync();
                }
            }

            logger?.LogInformation("[{Seeder}] Done. Ensured completed and cancelled booking scenarios.", Name);
        }
    }
}
