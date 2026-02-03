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
    /// Seeds saved properties across multiple tenant users.
    /// Each tenant saves 2-4 random properties from various owners.
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

            // Get all tenants
            var tenants = await context.Users
                .AsNoTracking()
                .Where(u => u.UserType == UserTypeEnum.Tenant)
                .Take(15)
                .ToListAsync();

            if (tenants.Count == 0)
            {
                logger?.LogWarning("[{Seeder}] No tenants found.", Name);
                return;
            }

            // Get all available properties (computed status: not under maintenance, not in unavailable period)
            var properties = await context.Properties
                .AsNoTracking()
                .Where(p => !p.IsUnderMaintenance)
                .Where(p => p.UnavailableFrom == null)
                .Select(p => p.PropertyId)
                .ToListAsync();

            if (properties.Count == 0)
            {
                logger?.LogWarning("[{Seeder}] No properties found.", Name);
                return;
            }

            var savedProperties = new List<UserSavedProperty>();
            
            foreach (var tenant in tenants)
            {
                // Each tenant saves 2-4 random properties
                int saveCount = Math.Min(Random.Shared.Next(2, 5), properties.Count);
                var tenantSavedIds = properties
                    .OrderBy(_ => Random.Shared.Next())
                    .Take(saveCount)
                    .ToList();

                foreach (var pid in tenantSavedIds)
                {
                    var exists = await context.UserSavedProperties
                        .AnyAsync(x => x.UserId == tenant.UserId && x.PropertyId == pid);
                    
                    if (!exists && !savedProperties.Any(sp => sp.UserId == tenant.UserId && sp.PropertyId == pid))
                    {
                        savedProperties.Add(new UserSavedProperty
                        {
                            UserId = tenant.UserId,
                            PropertyId = pid
                        });
                    }
                }
            }

            if (savedProperties.Count > 0)
            {
                await context.UserSavedProperties.AddRangeAsync(savedProperties);
                await context.SaveChangesAsync();
            }

            logger?.LogInformation("[{Seeder}] Done. Saved {Count} properties across {TenantCount} tenants.", Name, savedProperties.Count, tenants.Count);
        }
    }
}
