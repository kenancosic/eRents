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
    /// Seeds notifications for all user types - tenants receive booking/message notifications,
    /// owners receive booking requests and payment notifications.
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

            bool anyNotifications = await context.Notifications.AnyAsync();
            if (anyNotifications && !forceSeed)
            {
                logger?.LogInformation("[{Seeder}] Skipped (already has notifications)", Name);
                return;
            }

            var notifications = new List<Notification>();

            // Get tenants for tenant-type notifications
            var tenants = await context.Users.AsNoTracking()
                .Where(u => u.UserType == UserTypeEnum.Tenant)
                .Take(10)
                .ToListAsync();

            foreach (var tenant in tenants)
            {
                var booking = await context.Bookings.AsNoTracking()
                    .Where(b => b.UserId == tenant.UserId)
                    .OrderByDescending(b => b.BookingId)
                    .FirstOrDefaultAsync();

                // Booking confirmation notification
                if (booking != null)
                {
                    notifications.Add(new Notification
                    {
                        UserId = tenant.UserId,
                        Title = "Booking Confirmed",
                        Message = $"Your booking #{booking.BookingId} has been confirmed. Check-in starts on {booking.StartDate:d}.",
                        Type = "booking",
                        ReferenceId = booking.BookingId,
                        IsRead = Random.Shared.Next(3) == 0 // 33% read
                    });
                }

                // Message notification
                notifications.Add(new Notification
                {
                    UserId = tenant.UserId,
                    Title = "New Message",
                    Message = "You have a new message from a property owner.",
                    Type = "message",
                    IsRead = false
                });

                // Payment reminder for some users
                if (Random.Shared.Next(2) == 0)
                {
                    notifications.Add(new Notification
                    {
                        UserId = tenant.UserId,
                        Title = "Payment Reminder",
                        Message = "Your next rent payment is due in 3 days.",
                        Type = "payment",
                        IsRead = false
                    });
                }
            }

            // Get owners for owner-type notifications
            var owners = await context.Users.AsNoTracking()
                .Where(u => u.UserType == UserTypeEnum.Owner)
                .Take(5)
                .ToListAsync();

            foreach (var owner in owners)
            {
                var ownerProperties = await context.Properties.AsNoTracking()
                    .Where(p => p.OwnerId == owner.UserId)
                    .Select(p => p.PropertyId)
                    .ToListAsync();

                if (ownerProperties.Count == 0) continue;

                // Check for pending bookings requiring approval
                var pendingBooking = await context.Bookings.AsNoTracking()
                    .Where(b => ownerProperties.Contains(b.PropertyId) && b.Status == BookingStatusEnum.Pending)
                    .FirstOrDefaultAsync();

                if (pendingBooking != null)
                {
                    notifications.Add(new Notification
                    {
                        UserId = owner.UserId,
                        Title = "New Booking Request",
                        Message = "A tenant has requested to book your property. Review and approve.",
                        Type = "booking",
                        ReferenceId = pendingBooking.BookingId,
                        IsRead = false
                    });
                }

                // Payment received notification
                notifications.Add(new Notification
                {
                    UserId = owner.UserId,
                    Title = "Payment Received",
                    Message = "You have received a new rent payment.",
                    Type = "payment",
                    IsRead = Random.Shared.Next(2) == 0
                });

                // Maintenance issue notification
                var maintenanceIssue = await context.MaintenanceIssues.AsNoTracking()
                    .Where(m => ownerProperties.Contains(m.PropertyId))
                    .FirstOrDefaultAsync();

                if (maintenanceIssue != null)
                {
                    notifications.Add(new Notification
                    {
                        UserId = owner.UserId,
                        Title = "Maintenance Issue Reported",
                        Message = $"A tenant has reported a maintenance issue: {maintenanceIssue.Title}",
                        Type = "maintenance",
                        ReferenceId = maintenanceIssue.MaintenanceIssueId,
                        IsRead = false
                    });
                }

                // New review notification
                notifications.Add(new Notification
                {
                    UserId = owner.UserId,
                    Title = "New Property Review",
                    Message = "A tenant has left a review for your property.",
                    Type = "review",
                    IsRead = true
                });
            }

            if (notifications.Count > 0)
            {
                await context.Notifications.AddRangeAsync(notifications);
                await context.SaveChangesAsync();
            }

            logger?.LogInformation("[{Seeder}] Done. Seeded {Count} notifications across tenants and owners.", Name, notifications.Count);
        }
    }
}
