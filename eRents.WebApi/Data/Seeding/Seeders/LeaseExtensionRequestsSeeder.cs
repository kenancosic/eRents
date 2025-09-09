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
    /// Seeds a few pending LeaseExtensionRequests for monthly (subscription) bookings
    /// owned by the desktop landlord. Useful for demoing the desktop approval flow.
    /// </summary>
    public class LeaseExtensionRequestsSeeder : IDataSeeder
    {
        public int Order => 46; // After SubscriptionsSeeder (45)
        public string Name => nameof(LeaseExtensionRequestsSeeder);

        public async Task SeedAsync(ERentsContext context, ILogger logger, bool forceSeed = false)
        {
            logger?.LogInformation("[{Seeder}] Starting...", Name);

            if (forceSeed)
            {
                await context.LeaseExtensionRequests.IgnoreQueryFilters().ExecuteDeleteAsync();
            }

            // If there are already pending requests, skip to keep idempotency unless forceSeed
            if (!forceSeed && await context.LeaseExtensionRequests.AnyAsync())
            {
                logger?.LogInformation("[{Seeder}] Skipped (already present)", Name);
                return;
            }

            // Find owner 'desktop'
            var owner = await context.Users.AsNoTracking().FirstOrDefaultAsync(u => u.Username == "desktop");
            if (owner == null)
            {
                logger?.LogWarning("[{Seeder}] Owner user 'desktop' not found. Ensure UsersSeeder runs before this seeder.", Name);
                return;
            }

            // Find a couple of active monthly bookings for properties owned by 'desktop'
            var bookings = await context.Bookings
                .Include(b => b.Property)
                .AsNoTracking()
                .Where(b => b.Property.OwnerId == owner.UserId && b.Status == BookingStatusEnum.Active)
                .OrderBy(b => b.BookingId)
                .Take(2)
                .ToListAsync();

            if (bookings.Count == 0)
            {
                logger?.LogInformation("[{Seeder}] No active bookings for desktop owner; nothing to seed.", Name);
                return;
            }

            var today = DateOnly.FromDateTime(DateTime.UtcNow);

            foreach (var b in bookings)
            {
                // Skip if an open (pending) request already exists for this booking
                var exists = await context.LeaseExtensionRequests.AnyAsync(r => r.BookingId == b.BookingId && r.Status == LeaseExtensionStatusEnum.Pending);
                if (exists) continue;

                var req = new LeaseExtensionRequest
                {
                    BookingId = b.BookingId,
                    RequestedByUserId = b.UserId, // pretend tenant requested
                    OldEndDate = b.EndDate,
                    // Alternate between exact date request and +months request for demo variety
                    NewEndDate = (b.BookingId % 2 == 0) ? (b.EndDate?.AddMonths(2) ?? today.AddMonths(2)) : null,
                    ExtendByMonths = (b.BookingId % 2 != 0) ? 3 : null,
                    NewMonthlyAmount = null, // leave empty for seed
                    Reason = "I would like to extend my stay.",
                    Status = LeaseExtensionStatusEnum.Pending
                };

                await context.LeaseExtensionRequests.AddAsync(req);
            }

            await context.SaveChangesAsync();
            logger?.LogInformation("[{Seeder}] Done. Seeded pending lease extension requests where applicable.", Name);
        }
    }
}
