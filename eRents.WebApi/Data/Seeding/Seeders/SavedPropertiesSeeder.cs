using System.Linq;
using System.Threading.Tasks;
using eRents.Domain.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace eRents.WebApi.Data.Seeding.Seeders
{
    /// <summary>
    /// Seeds a minimal set of saved properties for a tenant user.
    /// Depends on Users and Properties baseline existing.
    /// </summary>
    public class SavedPropertiesSeeder : IDataSeeder
    {
        public int Order => 70; // after Maintenance issues
        public string Name => nameof(SavedPropertiesSeeder);

        public async Task SeedAsync(ERentsContext context, ILogger logger, bool forceSeed = false)
        {
            logger?.LogInformation("[{Seeder}] Starting...", Name);

            if (!forceSeed && await context.UserSavedProperties.AnyAsync())
            {
                logger?.LogInformation("[{Seeder}] Skipped (already present)", Name);
                return;
            }

            if (forceSeed)
            {
                await context.UserSavedProperties.IgnoreQueryFilters().ExecuteDeleteAsync();
            }

            var user = await context.Users.AsNoTracking().FirstOrDefaultAsync(u => u.Username == "mobile");
            if (user == null)
            {
                logger?.LogWarning("[{Seeder}] Prerequisite missing (user 'mobile').", Name);
                return;
            }

            var properties = await context.Properties
                .AsNoTracking()
                .OrderBy(p => p.PropertyId)
                .Take(2)
                .Select(p => p.PropertyId)
                .ToListAsync();
            if (properties.Count == 0)
            {
                logger?.LogWarning("[{Seeder}] No properties found.", Name);
                return;
            }

            foreach (var pid in properties)
            {
                var exists = await context.UserSavedProperties.AnyAsync(x => x.UserId == user.UserId && x.PropertyId == pid);
                if (!exists)
                {
                    await context.UserSavedProperties.AddAsync(new UserSavedProperty
                    {
                        UserId = user.UserId,
                        PropertyId = pid
                    });
                }
            }

            await context.SaveChangesAsync();
            logger?.LogInformation("[{Seeder}] Done. Ensured saved properties for user 'mobile'.", Name);
        }
    }
}
