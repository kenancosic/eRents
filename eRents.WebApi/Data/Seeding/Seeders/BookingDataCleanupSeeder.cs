using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using eRents.Domain.Models;
using eRents.Domain.Models.Enums;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace eRents.WebApi.Data.Seeding.Seeders
{
    /// <summary>
    /// Cleans up duplicate/overlapping bookings that may have been created by seeders.
    /// This should run FIRST (Order = 1) to ensure data integrity before other operations.
    /// 
    /// Rules:
    /// 1. A user should not have multiple non-cancelled bookings for the same property with overlapping dates
    /// 2. When duplicates are found, keeps the one with the highest BookingId (most recent) and cancels others
    /// 3. Also cleans up orphaned Tenant records where the associated booking is cancelled
    /// </summary>
    public class BookingDataCleanupSeeder : IDataSeeder
    {
        public int Order => 1; // Run FIRST before any other seeders
        public string Name => nameof(BookingDataCleanupSeeder);

        public async Task SeedAsync(ERentsContext context, ILogger logger, bool forceSeed = false)
        {
            logger?.LogInformation("[{Seeder}] Starting data cleanup...", Name);

            // Find all active/upcoming bookings grouped by user and property
            var allActiveBookings = await context.Bookings
                .Where(b => b.Status != BookingStatusEnum.Cancelled && b.Status != BookingStatusEnum.Completed)
                .OrderByDescending(b => b.BookingId)
                .ToListAsync();

            // Group by user + property to find potential duplicates
            var groupedBookings = allActiveBookings
                .GroupBy(b => new { b.UserId, b.PropertyId })
                .Where(g => g.Count() > 1)
                .ToList();

            int duplicatesFixed = 0;
            int tenantsFixed = 0;

            foreach (var group in groupedBookings)
            {
                var bookings = group.OrderByDescending(b => b.BookingId).ToList();
                
                // Keep the most recent booking (highest ID), cancel others if they overlap
                var keepBooking = bookings.First();
                
                foreach (var duplicateBooking in bookings.Skip(1))
                {
                    // Check if dates overlap with the booking we're keeping
                    var keepStart = keepBooking.StartDate;
                    var keepEnd = keepBooking.EndDate ?? DateOnly.MaxValue;
                    var dupStart = duplicateBooking.StartDate;
                    var dupEnd = duplicateBooking.EndDate ?? DateOnly.MaxValue;

                    bool overlaps = dupStart <= keepEnd && dupEnd >= keepStart;

                    if (overlaps)
                    {
                        logger?.LogWarning(
                            "[{Seeder}] Found duplicate booking: BookingId={DupId} overlaps with BookingId={KeepId} for User={UserId} Property={PropertyId}. Cancelling duplicate.",
                            Name, duplicateBooking.BookingId, keepBooking.BookingId, group.Key.UserId, group.Key.PropertyId);

                        duplicateBooking.Status = BookingStatusEnum.Cancelled;
                        duplicateBooking.UpdatedAt = DateTime.UtcNow;
                        duplicatesFixed++;

                        // Also cancel the associated subscription if exists
                        if (duplicateBooking.SubscriptionId.HasValue)
                        {
                            var subscription = await context.Subscriptions
                                .FirstOrDefaultAsync(s => s.SubscriptionId == duplicateBooking.SubscriptionId.Value);
                            if (subscription != null)
                            {
                                subscription.Status = SubscriptionStatusEnum.Cancelled;
                            }
                        }
                    }
                }
            }

            // Clean up Tenant records for cancelled bookings
            var cancelledBookingUserPropertyPairs = await context.Bookings
                .Where(b => b.Status == BookingStatusEnum.Cancelled)
                .Select(b => new { b.UserId, b.PropertyId })
                .Distinct()
                .ToListAsync();

            foreach (var pair in cancelledBookingUserPropertyPairs)
            {
                // Check if there's an active booking for this user/property
                var hasActiveBooking = await context.Bookings
                    .AnyAsync(b => b.UserId == pair.UserId 
                                && b.PropertyId == pair.PropertyId 
                                && b.Status != BookingStatusEnum.Cancelled 
                                && b.Status != BookingStatusEnum.Completed);

                if (!hasActiveBooking)
                {
                    // No active booking, update Tenant status to LeaseEnded
                    var tenant = await context.Tenants
                        .FirstOrDefaultAsync(t => t.UserId == pair.UserId && t.PropertyId == pair.PropertyId);

                    if (tenant != null && tenant.TenantStatus == TenantStatusEnum.Active)
                    {
                        logger?.LogInformation(
                            "[{Seeder}] Fixing orphaned tenant: TenantId={TenantId} for User={UserId} Property={PropertyId}. Setting status to LeaseEnded.",
                            Name, tenant.TenantId, pair.UserId, pair.PropertyId);

                        tenant.TenantStatus = TenantStatusEnum.LeaseEnded;
                        tenantsFixed++;
                    }
                }
            }

            if (duplicatesFixed > 0 || tenantsFixed > 0)
            {
                await context.SaveChangesAsync();
                logger?.LogInformation("[{Seeder}] Done. Fixed {DuplicateCount} duplicate bookings and {TenantCount} orphaned tenants.", 
                    Name, duplicatesFixed, tenantsFixed);
            }
            else
            {
                logger?.LogInformation("[{Seeder}] Done. No data cleanup needed.", Name);
            }
        }
    }
}
