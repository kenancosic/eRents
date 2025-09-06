using System.Linq;
using System.Threading.Tasks;
using eRents.Domain.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace eRents.WebApi.Data.Seeding.Seeders
{
    public class AmenitySeeder : IDataSeeder
    {
        public int Order => 10;
        public string Name => nameof(AmenitySeeder);

        public async Task SeedAsync(ERentsContext context, ILogger logger, bool forceSeed = false)
        {
            logger?.LogInformation("[{Seeder}] Starting...", Name);

            // Idempotent: skip if any amenities exist (BL seeder also seeds these)
            if (!forceSeed && await context.Amenities.AnyAsync())
            {
                logger?.LogInformation("[{Seeder}] Skipped (already present)", Name);
                return;
            }

            // If forceSeed, clear amenities only (safe, will not touch other tables)
            if (forceSeed)
            {
                await context.Amenities.ExecuteDeleteAsync();
            }

            var amenityNames = new[]
            {
                "WiFi", "Parking", "Air Conditioning", "Heating", "Kitchen",
                "TV", "Washing Machine", "Balcony", "Pet Friendly", "Swimming Pool",
                "Central Heating", "Terrace", "Garden", "Garage", "Elevator",
                "Furnished", "Near Public Transport", "City View", "Mountain View", 
                "River View", "Close to Old Town", "Close to University", "Gym Access"
            };

            var existing = await context.Amenities.Select(a => a.AmenityName).ToListAsync();
            var toAdd = amenityNames.Except(existing).Select(n => new Amenity { AmenityName = n }).ToList();
            if (toAdd.Count > 0)
            {
                await context.Amenities.AddRangeAsync(toAdd);
                await context.SaveChangesAsync();
            }

            logger?.LogInformation("[{Seeder}] Done. Added {Count} amenities.", Name, toAdd.Count);
        }
    }
}
