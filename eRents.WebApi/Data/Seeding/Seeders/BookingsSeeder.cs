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
	/// Seeds a minimal set of bookings to support baseline demos.
	/// Depends on Users and Properties baseline existing.
	/// </summary>
	public class BookingsSeeder : IDataSeeder
	{
		public int Order => 40; // after PropertiesSeeder
		public string Name => nameof(BookingsSeeder);

		public async Task SeedAsync(ERentsContext context, ILogger logger, bool forceSeed = false)
		{
			logger?.LogInformation("[{Seeder}] Starting...", Name);

			if (!forceSeed && await context.Bookings.AnyAsync())
			{
				logger?.LogInformation("[{Seeder}] Skipped (already present)", Name);
				return;
			}

			if (forceSeed)
			{
				await context.Payments.IgnoreQueryFilters().ExecuteDeleteAsync();
				await context.Tenants.IgnoreQueryFilters().ExecuteDeleteAsync();
				await context.Bookings.IgnoreQueryFilters().ExecuteDeleteAsync();
			}

			// Use existing tenant and available properties
			var tenant = await context.Users.AsNoTracking().FirstOrDefaultAsync(u => u.Username == "mobile");
			var tenantSarajevo = await context.Users.AsNoTracking().FirstOrDefaultAsync(u => u.Username == "tenant_sarajevo");
			var tenantMostar = await context.Users.AsNoTracking().FirstOrDefaultAsync(u => u.Username == "tenant_mostar");
			var desktopOwner = await context.Users.AsNoTracking().FirstOrDefaultAsync(u => u.Username == "desktop");

			var properties = await context.Properties.Include(p => p.Address).AsNoTracking().ToListAsync();
			var property = properties.FirstOrDefault();

			if (tenant == null || property == null)
			{
				logger?.LogWarning("[{Seeder}] Prerequisites missing (tenant or property). Ensure Users/Properties seeders ran.", Name);
				return;
			}

			var today = DateOnly.FromDateTime(DateTime.UtcNow);
			var bookings = new List<Booking>();
			var tenants = new List<Tenant>();

			// Track user+property combinations we're adding in this batch to prevent duplicates
			var addedBookings = new HashSet<(int UserId, int PropertyId)>();

			// Helper to check if an active/upcoming booking already exists for user+property
			// Checks BOTH the database AND the in-memory batch being built
			async Task<bool> HasActiveBooking(int userId, int propertyId)
			{
				// Check in-memory batch first
				if (addedBookings.Contains((userId, propertyId)))
					return true;

				// Then check database
				return await context.Bookings.AnyAsync(b =>
					b.UserId == userId &&
					b.PropertyId == propertyId &&
					b.Status != BookingStatusEnum.Cancelled &&
					b.Status != BookingStatusEnum.Completed);
			}

			// Create booking for mobile tenant (only if none exists)
			if (!await HasActiveBooking(tenant.UserId, property.PropertyId))
			{
				var booking1 = new Booking
				{
					PropertyId = property.PropertyId,
					UserId = tenant.UserId,
					StartDate = today.AddMonths(-1),
					EndDate = today.AddMonths(5),
					TotalPrice = Math.Max(1m, property.Price) * 6,
					Status = BookingStatusEnum.Active,
					PaymentStatus = "Paid",
					PaymentMethod = "Stripe",
					Currency = property.Currency ?? "USD",
					IsSubscription = true // Monthly rental
				};
				bookings.Add(booking1);
				addedBookings.Add((tenant.UserId, property.PropertyId));

				// Link tenant record for the first booking
				var existingTenancy1 = await context.Tenants.FirstOrDefaultAsync(t => t.UserId == tenant.UserId && t.PropertyId == property.PropertyId);
				if (existingTenancy1 == null)
				{
					var tenancy1 = new Tenant
					{
						UserId = tenant.UserId,
						PropertyId = property.PropertyId,
						LeaseStartDate = booking1.StartDate,
						LeaseEndDate = booking1.EndDate,
						TenantStatus = TenantStatusEnum.Active
					};
					tenants.Add(tenancy1);
				}
			}

			// Payments will be created AFTER bookings are saved (to get generated BookingIds)

			// Create additional bookings for BH users if we have enough properties
			if (properties.Count > 1 && tenantSarajevo != null && !await HasActiveBooking(tenantSarajevo.UserId, properties[1].PropertyId))
			{
				var property2 = properties[1];
				var booking2 = new Booking
				{
					PropertyId = property2.PropertyId,
					UserId = tenantSarajevo.UserId,
					StartDate = today.AddDays(10),
					EndDate = today.AddMonths(3),
					TotalPrice = Math.Max(1m, property2.Price) * 3,
					Status = BookingStatusEnum.Active,
					PaymentStatus = "Paid",
					PaymentMethod = "Stripe",
					Currency = property2.Currency ?? "USD",
					IsSubscription = true
				};
				bookings.Add(booking2);
				addedBookings.Add((tenantSarajevo.UserId, property2.PropertyId));

				var existingTenancy2 = await context.Tenants.FirstOrDefaultAsync(t => t.UserId == tenantSarajevo.UserId && t.PropertyId == property2.PropertyId);
				if (existingTenancy2 == null)
				{
					var tenancy2 = new Tenant
					{
						UserId = tenantSarajevo.UserId,
						PropertyId = property2.PropertyId,
						LeaseStartDate = booking2.StartDate,
						LeaseEndDate = booking2.EndDate,
						TenantStatus = TenantStatusEnum.Active
					};
					tenants.Add(tenancy2);
				}

				// Payment for booking2 will be created AFTER bookings are saved
			}

			if (properties.Count > 2 && tenantMostar != null && !await HasActiveBooking(tenantMostar.UserId, properties[2].PropertyId))
			{
				var property3 = properties[2];
				var booking3 = new Booking
				{
					PropertyId = property3.PropertyId,
					UserId = tenantMostar.UserId,
					StartDate = today.AddMonths(1),
					EndDate = today.AddMonths(4),
					TotalPrice = Math.Max(1m, property3.Price) * 3,
					Status = BookingStatusEnum.Upcoming,
					PaymentStatus = "Pending",
					PaymentMethod = "Stripe",
					Currency = property3.Currency ?? "USD",
					IsSubscription = true
				};
				bookings.Add(booking3);
				addedBookings.Add((tenantMostar.UserId, property3.PropertyId));

				// Upcoming booking - tenant status is Active for confirmed bookings
				var existingTenancy3 = await context.Tenants.FirstOrDefaultAsync(t => t.UserId == tenantMostar.UserId && t.PropertyId == property3.PropertyId);
				if (existingTenancy3 == null)
				{
					var tenancy3 = new Tenant
					{
						UserId = tenantMostar.UserId,
						PropertyId = property3.PropertyId,
						LeaseStartDate = booking3.StartDate,
						LeaseEndDate = booking3.EndDate,
						TenantStatus = TenantStatusEnum.Active
					};
					tenants.Add(tenancy3);
				}
			}

			// Create active monthly subscription booking for desktop owner's property
			// This enables testing of lease extension requests in the desktop app
			if (desktopOwner != null && tenant != null)
			{
				var desktopMonthlyProperty = properties.FirstOrDefault(p => 
					p.OwnerId == desktopOwner.UserId && p.RentingType == RentalType.Monthly);
				
				if (desktopMonthlyProperty != null && !await HasActiveBooking(tenant.UserId, desktopMonthlyProperty.PropertyId))
				{
					var subscriptionBooking = new Booking
					{
						PropertyId = desktopMonthlyProperty.PropertyId,
						UserId = tenant.UserId,
						StartDate = today.AddMonths(-2),
						EndDate = today.AddMonths(4),
						TotalPrice = Math.Max(1m, desktopMonthlyProperty.Price) * 6,
						Status = BookingStatusEnum.Active,
						PaymentStatus = "Paid",
						Currency = desktopMonthlyProperty.Currency ?? "USD",
						IsSubscription = true // Required for lease extension requests
					};
					bookings.Add(subscriptionBooking);
					addedBookings.Add((tenant.UserId, desktopMonthlyProperty.PropertyId));

					var existingSubscriptionTenancy = await context.Tenants.FirstOrDefaultAsync(t => t.UserId == tenant.UserId && t.PropertyId == desktopMonthlyProperty.PropertyId);
					if (existingSubscriptionTenancy == null)
					{
						var subscriptionTenancy = new Tenant
						{
							UserId = tenant.UserId,
							PropertyId = desktopMonthlyProperty.PropertyId,
							LeaseStartDate = subscriptionBooking.StartDate,
							LeaseEndDate = subscriptionBooking.EndDate,
							TenantStatus = TenantStatusEnum.Active
						};
						tenants.Add(subscriptionTenancy);
					}
				}
			}

			if (bookings.Count == 0)
			{
				logger?.LogInformation("[{Seeder}] No new bookings to add (all already exist).", Name);
				return;
			}

			await context.Bookings.AddRangeAsync(bookings);
			await context.Tenants.AddRangeAsync(tenants);
			await context.SaveChangesAsync();

			// Now that BookingIds exist, create payments safely
			var payments = new List<Payment>();

			// Create payments for each booking added
			foreach (var booking in bookings)
			{
				var tenantRecord = tenants.FirstOrDefault(t => t.UserId == booking.UserId && t.PropertyId == booking.PropertyId);
				var bookingProperty = properties.FirstOrDefault(p => p.PropertyId == booking.PropertyId);
				var monthly = Math.Max(1m, bookingProperty?.Price ?? 1m);

				payments.Add(new Payment 
				{ 
					PropertyId = booking.PropertyId, 
					BookingId = booking.BookingId, 
					TenantId = tenantRecord?.TenantId, 
					Amount = monthly, 
					Currency = booking.Currency, 
					PaymentMethod = "Stripe", 
					PaymentStatus = "Completed", 
					PaymentType = "BookingPayment" 
				});
			}

			if (payments.Count > 0)
			{
				await context.Payments.AddRangeAsync(payments);
				await context.SaveChangesAsync();
			}

			logger?.LogInformation("[{Seeder}] Done. Added {BookingCount} bookings, {TenantCount} tenancies and {PaymentCount} payments.", Name, bookings.Count, tenants.Count, payments.Count);
		}
	}
}
