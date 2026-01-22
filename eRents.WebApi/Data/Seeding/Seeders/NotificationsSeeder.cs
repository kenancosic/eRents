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
                    var property = await context.Properties.AsNoTracking()
                        .FirstOrDefaultAsync(p => p.PropertyId == booking.PropertyId);
                    var propertyName = property?.Name ?? "your property";
                    
                    notifications.Add(new Notification
                    {
                        UserId = tenant.UserId,
                        Title = "Booking Confirmed",
                        Message = $"Your booking at {propertyName} has been confirmed. Check-in starts on {booking.StartDate:d}.",
                        Type = "booking",
                        ReferenceId = booking.BookingId,
                        IsRead = Random.Shared.Next(3) == 0, // 33% read
                        CreatedAt = DateTime.UtcNow.AddDays(-Random.Shared.Next(1, 14)),
                        UpdatedAt = DateTime.UtcNow.AddDays(-Random.Shared.Next(1, 14))
                    });
                }

                // Message notification
                notifications.Add(new Notification
                {
                    UserId = tenant.UserId,
                    Title = "New Message",
                    Message = "You have a new message from a property owner.",
                    Type = "message",
                    IsRead = false,
                    CreatedAt = DateTime.UtcNow.AddHours(-Random.Shared.Next(1, 48)),
                    UpdatedAt = DateTime.UtcNow.AddHours(-Random.Shared.Next(1, 48))
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
                        IsRead = false,
                        CreatedAt = DateTime.UtcNow.AddDays(-1),
                        UpdatedAt = DateTime.UtcNow.AddDays(-1)
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
                    var pendingProperty = await context.Properties.AsNoTracking()
                        .FirstOrDefaultAsync(p => p.PropertyId == pendingBooking.PropertyId);
                    
                    notifications.Add(new Notification
                    {
                        UserId = owner.UserId,
                        Title = "New Booking Request",
                        Message = $"A tenant has requested to book {pendingProperty?.Name ?? "your property"}. Review and approve.",
                        Type = "booking",
                        ReferenceId = pendingBooking.BookingId,
                        IsRead = false,
                        CreatedAt = DateTime.UtcNow.AddHours(-Random.Shared.Next(2, 72)),
                        UpdatedAt = DateTime.UtcNow.AddHours(-Random.Shared.Next(2, 72))
                    });
                }

                // Payment received notification
                var recentPayment = await context.Payments.AsNoTracking()
                    .Where(p => ownerProperties.Contains(p.PropertyId ?? 0) && p.PaymentStatus == "Completed")
                    .OrderByDescending(p => p.CreatedAt)
                    .FirstOrDefaultAsync();
                    
                notifications.Add(new Notification
                {
                    UserId = owner.UserId,
                    Title = "Payment Received",
                    Message = recentPayment != null 
                        ? $"You received a payment of {recentPayment.Amount:C} {recentPayment.Currency}."
                        : "You have received a new rent payment.",
                    Type = "payment",
                    ReferenceId = recentPayment?.PaymentId,
                    IsRead = Random.Shared.Next(2) == 0,
                    CreatedAt = DateTime.UtcNow.AddDays(-Random.Shared.Next(1, 7)),
                    UpdatedAt = DateTime.UtcNow.AddDays(-Random.Shared.Next(1, 7))
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
                        IsRead = false,
                        CreatedAt = DateTime.UtcNow.AddDays(-Random.Shared.Next(1, 10)),
                        UpdatedAt = DateTime.UtcNow.AddDays(-Random.Shared.Next(1, 10))
                    });
                }

                // New review notification with property reference
                var recentReview = await context.Reviews.AsNoTracking()
                    .Where(r => ownerProperties.Contains(r.PropertyId ?? 0))
                    .OrderByDescending(r => r.CreatedAt)
                    .FirstOrDefaultAsync();
                var reviewProperty = recentReview != null 
                    ? await context.Properties.AsNoTracking().FirstOrDefaultAsync(p => p.PropertyId == recentReview.PropertyId)
                    : null;
                    
                notifications.Add(new Notification
                {
                    UserId = owner.UserId,
                    Title = "New Property Review",
                    Message = reviewProperty != null 
                        ? $"A tenant has left a {recentReview?.StarRating:F1}-star review for {reviewProperty.Name}."
                        : "A tenant has left a review for your property.",
                    Type = "review",
                    ReferenceId = recentReview?.ReviewId,
                    IsRead = true,
                    CreatedAt = DateTime.UtcNow.AddDays(-Random.Shared.Next(3, 21)),
                    UpdatedAt = DateTime.UtcNow.AddDays(-Random.Shared.Next(3, 21))
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
