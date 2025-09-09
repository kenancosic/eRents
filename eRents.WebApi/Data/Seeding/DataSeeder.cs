using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using eRents.Domain.Models;
using Microsoft.EntityFrameworkCore;

namespace eRents.WebApi.Data.Seeding
{
	public class DataSeeder
	{
		private readonly ILogger<DataSeeder> _logger;
		private readonly IDataSeeder[] _seeders;

		public DataSeeder(
				ILogger<DataSeeder> logger,
				IEnumerable<IDataSeeder> seeders)
		{
			_logger = logger;
			_seeders = seeders.OrderBy(s => s.Order).ToArray();
		}

		// forceSeed: ask each seeder to clear its own scope first
		public async Task SeedAllAsync(ERentsContext context, bool forceSeed = false)
		{
			_logger?.LogInformation("Starting DataSeeder. forceSeed={ForceSeed}", forceSeed);

			// Temporarily increase command timeout during seeding to avoid timeouts on large inserts
			var previousTimeout = context.Database.GetCommandTimeout();
			context.Database.SetCommandTimeout(TimeSpan.FromMinutes(2));
			try
			{
				foreach (var seeder in _seeders)
				{
					_logger?.LogInformation("Running seeder {SeederName} (Order {Order}) ...", seeder.Name, seeder.Order);
					await seeder.SeedAsync(context, _logger, forceSeed);
					// Prevent cross-seeder tracking conflicts (e.g., attaching same keys with different instances)
					context.ChangeTracker.Clear();
				}
			}
			finally
			{
				// Restore previous timeout
				context.Database.SetCommandTimeout(previousTimeout);
			}

			_logger?.LogInformation("DataSeeder completed.");
		}
	}
}