using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using eRents.Domain.Models;

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

            foreach (var seeder in _seeders)
            {
                _logger?.LogInformation("Running seeder {SeederName} (Order {Order}) ...", seeder.Name, seeder.Order);
                await seeder.SeedAsync(context, _logger, forceSeed);
                // Prevent cross-seeder tracking conflicts (e.g., attaching same keys with different instances)
                context.ChangeTracker.Clear();
            }

            _logger?.LogInformation("DataSeeder completed.");
        }
    }
}