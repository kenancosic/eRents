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
    /// Seeds daily rental bookings with various statuses (Upcoming, Active, Completed).
    /// Daily rentals are auto-approved after payment and never require landlord approval.
    /// Creates bookings across multiple tenants and daily rental properties.
    /// </summary>
    public class DailyRentalBookingsSeeder : IDataSeeder
    {
        public int Order => 42; // After BookingsVarietySeeder (41)
        public string Name => nameof(DailyRentalBookingsSeeder);

        public async Task SeedAsync(ERentsContext context, ILogger logger, bool forceSeed = false)
        {
            logger?.LogInformation("[{Seeder}] Starting...", Name);

            // Check if daily rental bookings already exist (check for Upcoming status as our marker)
            var hasDailyBookings = await context.Bookings
                .Include(b => b.Property)
                .AnyAsync(b => b.Property.RentingType == RentalType.Daily && b.Status == BookingStatusEnum.Upcoming);

            if (!forceSeed && hasDailyBookings)
            {
                logger?.LogInformation("[{Seeder}] Skipped (daily rental bookings already present)", Name);
                return;
            }

            if (forceSeed)
            {
                // Delete daily rental bookings created by this seeder
                var dailyBookingIds = await context.Bookings
                    .Include(b => b.Property)
                    .Where(b => b.Property.RentingType == RentalType.Daily)
                    .Select(b => b.BookingId)
                    .ToListAsync();

                if (dailyBookingIds.Count > 0)
                {
                    await context.Payments.Where(p => dailyBookingIds.Contains(p.BookingId ?? 0)).ExecuteDeleteAsync();
                    await context.Bookings.Where(b => dailyBookingIds.Contains(b.BookingId)).ExecuteDeleteAsync();
                }
            }

            // Get daily rental properties (especially those requiring approval)
            var dailyProperties = await context.Properties
                .AsNoTracking()
                .Where(p => p.RentingType == RentalType.Daily)
                .Where(p => !p.IsUnderMaintenance)
                .ToListAsync();

            if (dailyProperties.Count == 0)
            {
                logger?.LogInformation("[{Seeder}] No daily rental properties found; skipping.", Name);
                return;
            }

            // Get tenants for booking creation
            var tenants = await context.Users
                .AsNoTracking()
                .Where(u => u.UserType == UserTypeEnum.Tenant)
                .Take(10)
                .ToListAsync();

            if (tenants.Count == 0)
            {
                logger?.LogInformation("[{Seeder}] No tenants found; skipping.", Name);
                return;
            }

            var today = DateOnly.FromDateTime(DateTime.UtcNow);
            var bookings = new List<Booking>();
            int tenantIndex = 0;

            foreach (var property in dailyProperties.Take(6))
            {
                var tenant = tenants[tenantIndex % tenants.Count];
                tenantIndex++;

                // Create an upcoming booking (future, auto-approved - daily rentals never require approval)
                var upcomingBooking = new Booking
                {
                    PropertyId = property.PropertyId,
                    UserId = tenant.UserId,
                    StartDate = today.AddDays(14 + Random.Shared.Next(1, 30)),
                    EndDate = today.AddDays(14 + Random.Shared.Next(35, 45)),
                    TotalPrice = Math.Max(1m, property.Price) * Random.Shared.Next(3, 10),
                    // Daily rentals are auto-approved after payment - never Pending
                    Status = BookingStatusEnum.Upcoming,
                    PaymentStatus = "Paid",
                    Currency = property.Currency ?? "USD",
                    IsSubscription = false
                };
                bookings.Add(upcomingBooking);

                // Create an active daily booking (started)
                if (tenantIndex < tenants.Count)
                {
                    var nextTenant = tenants[tenantIndex % tenants.Count];
                    tenantIndex++;

                    var activeBooking = new Booking
                    {
                        PropertyId = property.PropertyId,
                        UserId = nextTenant.UserId,
                        StartDate = today.AddDays(-3),
                        EndDate = today.AddDays(4),
                        TotalPrice = Math.Max(1m, property.Price) * 7,
                        Status = BookingStatusEnum.Active,
                        PaymentStatus = "Paid",
                        Currency = property.Currency ?? "USD",
                        IsSubscription = false
                    };
                    bookings.Add(activeBooking);
                }
            }

            // Add some historical completed daily bookings
            var completedTenant = tenants.FirstOrDefault();
            if (completedTenant != null && dailyProperties.Count > 0)
            {
                var property = dailyProperties.First();
                bookings.Add(new Booking
                {
                    PropertyId = property.PropertyId,
                    UserId = completedTenant.UserId,
                    StartDate = today.AddDays(-60),
                    EndDate = today.AddDays(-53),
                    TotalPrice = Math.Max(1m, property.Price) * 7,
                    Status = BookingStatusEnum.Completed,
                    PaymentStatus = "Completed",
                    Currency = property.Currency ?? "USD",
                    IsSubscription = false
                });
            }

            await context.Bookings.AddRangeAsync(bookings);
            await context.SaveChangesAsync();

            // Create payments for all daily bookings (they are auto-approved after payment)
            var payments = new List<Payment>();
            foreach (var booking in bookings)
            {
                payments.Add(new Payment
                {
                    PropertyId = booking.PropertyId,
                    BookingId = booking.BookingId,
                    Amount = booking.TotalPrice,
                    Currency = booking.Currency,
                    PaymentMethod = "Stripe",
                    PaymentStatus = booking.Status == BookingStatusEnum.Completed ? "Completed" : "Paid",
                    PaymentType = "BookingPayment",
                    PaymentReference = $"DR_{booking.BookingId}_{Guid.NewGuid().ToString("N").Substring(0, 8)}"
                });
            }

            if (payments.Count > 0)
            {
                await context.Payments.AddRangeAsync(payments);
                await context.SaveChangesAsync();
            }

            logger?.LogInformation("[{Seeder}] Done. Added {BookingCount} daily rental bookings and {PaymentCount} payments.", Name, bookings.Count, payments.Count);
        }
    }
}
