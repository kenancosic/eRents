using eRents.Domain.Models;
using Microsoft.EntityFrameworkCore;

namespace eRents.WebApi.Data.Seeding.Seeders
{
	/// <summary>
	/// Creates pending payment invoices for test tenant users to ensure they have 
	/// visible invoices in the mobile app's Invoices screen.
	/// </summary>
	public class InvoicesSeeder : IDataSeeder
	{
		public int Order => 53; // After PaymentsSeeder (52)
		public string Name => nameof(InvoicesSeeder);

		public async Task SeedAsync(ERentsContext context, ILogger logger, bool forceSeed = false)
		{
			logger?.LogInformation("[{Seeder}] Starting...", Name);

			// Find the "mobile" test tenant user
			var mobileUser = await context.Users
					.AsNoTracking()
					.FirstOrDefaultAsync(u => u.Username == "mobile");

			if (mobileUser == null)
			{
				logger?.LogWarning("[{Seeder}] Mobile test user not found - skipping", Name);
				return;
			}

			// Check if mobile user already has pending invoices
			var existingPendingCount = await context.Payments
					.CountAsync(p => p.TenantId == mobileUser.UserId
							&& p.PaymentStatus == "Pending"
							&& p.PaymentType == "SubscriptionPayment");

			if (existingPendingCount >= 2 && !forceSeed)
			{
				logger?.LogInformation("[{Seeder}] Skipped (mobile user already has {Count} pending invoices)", Name, existingPendingCount);
				return;
			}

			// Find tenant record for mobile user
			var tenant = await context.Tenants
					.Include(t => t.Property)
					.FirstOrDefaultAsync(t => t.UserId == mobileUser.UserId);

			if (tenant == null)
			{
				// Create a tenant record if none exists - link to first available property
				var property = await context.Properties.FirstOrDefaultAsync();
				if (property == null)
				{
					logger?.LogWarning("[{Seeder}] No properties found - cannot create invoices", Name);
					return;
				}

				tenant = new Tenant
				{
					UserId = mobileUser.UserId,
					PropertyId = property.PropertyId,
					LeaseStartDate = DateOnly.FromDateTime(DateTime.UtcNow.AddMonths(-2)),
					LeaseEndDate = DateOnly.FromDateTime(DateTime.UtcNow.AddMonths(10))
				};
				await context.Tenants.AddAsync(tenant);
				await context.SaveChangesAsync();

				// Reload with property
				tenant = await context.Tenants
						.Include(t => t.Property)
						.FirstAsync(t => t.TenantId == tenant.TenantId);
			}

			var now = DateTime.UtcNow;
			var invoicesCreated = 0;

			// Create 3 pending invoices for the mobile user
			var invoiceDates = new[]
			{
								now.AddDays(-5),  // Overdue
                now.AddDays(10),  // Due soon
                now.AddDays(25),  // Future
            };

			foreach (var dueDate in invoiceDates)
			{
				var payment = new Payment
				{
					TenantId = tenant.TenantId,
					PropertyId = tenant.PropertyId,
					Amount = tenant.Property?.Price ?? 500m,
					Currency = tenant.Property?.Currency ?? "USD",
					PaymentMethod = "Stripe",
					PaymentStatus = "Pending",
					PaymentType = "SubscriptionPayment",
					DueDate = dueDate,
					CreatedAt = dueDate.AddDays(-25), // Created ~25 days before due
					UpdatedAt = dueDate.AddDays(-25)
				};

				await context.Payments.AddAsync(payment);
				invoicesCreated++;
			}

			await context.SaveChangesAsync();
			logger?.LogInformation("[{Seeder}] Created {Count} pending invoices for mobile user", Name, invoicesCreated);
		}
	}
}
