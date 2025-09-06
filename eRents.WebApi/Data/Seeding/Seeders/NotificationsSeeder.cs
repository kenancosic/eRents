using System;
using System.Linq;
using System.Threading.Tasks;
using eRents.Domain.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace eRents.WebApi.Data.Seeding.Seeders
{
    /// <summary>
    /// Seeds a few notifications for the mobile user related to booking and messages.
    /// </summary>
    public class NotificationsSeeder : IDataSeeder
    {
        public int Order => 80; // after messages
        public string Name => nameof(NotificationsSeeder);

        public async Task SeedAsync(ERentsContext context, ILogger logger, bool forceSeed = false)
        {
            logger?.LogInformation("[{Seeder}] Starting...", Name);

            if (forceSeed)
            {
                await context.Notifications.IgnoreQueryFilters().ExecuteDeleteAsync();
            }

            var mobile = await context.Users.AsNoTracking().FirstOrDefaultAsync(u => u.Username == "mobile");
            if (mobile == null)
            {
                logger?.LogInformation("[{Seeder}] Skipped (user 'mobile' not found)", Name);
                return;
            }

            bool any = await context.Notifications.AnyAsync(n => n.UserId == mobile.UserId);
            if (any && !forceSeed)
            {
                logger?.LogInformation("[{Seeder}] Skipped (already has notifications)", Name);
                return;
            }

            var lastBooking = await context.Bookings.AsNoTracking()
                .Where(b => b.UserId == mobile.UserId)
                .OrderByDescending(b => b.BookingId)
                .FirstOrDefaultAsync();

            await context.Notifications.AddRangeAsync(
                new Notification { UserId = mobile.UserId, Title = "New Message", Message = "Owner replied to your inquiry.", Type = "message", IsRead = false },
                new Notification { UserId = mobile.UserId, Title = "Booking Update", Message = lastBooking != null ? $"Your booking #{lastBooking.BookingId} is confirmed." : "Your booking status was updated.", Type = "booking", ReferenceId = lastBooking?.BookingId, IsRead = false }
            );

            await context.SaveChangesAsync();
            logger?.LogInformation("[{Seeder}] Done. Seeded notifications for user 'mobile'.", Name);
        }
    }
}
