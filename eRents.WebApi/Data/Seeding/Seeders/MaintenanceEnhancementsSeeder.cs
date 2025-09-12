using System;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using eRents.Domain.Models;
using eRents.Domain.Models.Enums;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace eRents.WebApi.Data.Seeding.Seeders
{
    /// <summary>
    /// Enhances existing maintenance issues with assignments, resolution data, and extra images.
    /// </summary>
    public class MaintenanceEnhancementsSeeder : IDataSeeder
    {
        public int Order => 62; // After MaintenanceIssuesSeeder (60) and before Messages/Notifications
        public string Name => nameof(MaintenanceEnhancementsSeeder);

        public async Task SeedAsync(ERentsContext context, ILogger logger, bool forceSeed = false)
        {
            logger?.LogInformation("[{Seeder}] Starting...", Name);

            // Load a couple of issues
            var issues = await context.MaintenanceIssues
                .OrderBy(i => i.MaintenanceIssueId)
                .Take(3)
                .ToListAsync();

            if (issues.Count == 0)
            {
                logger?.LogInformation("[{Seeder}] No maintenance issues found; skipping.", Name);
                return;
            }

            // Get assignable users
            var desktop = await context.Users.AsNoTracking().FirstOrDefaultAsync(u => u.Username == "desktop");
            var ownerZenica = await context.Users.AsNoTracking().FirstOrDefaultAsync(u => u.Username == "owner_zenica");

            int updates = 0;
            if (issues.Count > 0)
            {
                var first = issues[0];
                if (forceSeed || first.Status != MaintenanceIssueStatusEnum.Completed || first.Cost == null)
                {
                    first.AssignedToUserId = desktop?.UserId;
                    first.Status = MaintenanceIssueStatusEnum.Completed;
                    first.Cost = 45.00m;
                    first.ResolutionNotes = "Zamijenjena brtva i zategnuta slavina. Problem riješen.";
                    first.ResolvedAt = DateTime.UtcNow.AddDays(-2);
                    updates++;
                }
            }

            if (issues.Count > 1)
            {
                var second = issues[1];
                if (forceSeed || second.Status == MaintenanceIssueStatusEnum.Pending || second.AssignedToUserId == null)
                {
                    second.AssignedToUserId = ownerZenica?.UserId ?? desktop?.UserId;
                    second.Status = MaintenanceIssueStatusEnum.InProgress;
                    second.ResolutionNotes = "U toku je nabavka rezervnih dijelova.";
                    updates++;
                }
            }

            // Attach additional images to third issue if available
            if (issues.Count > 2)
            {
                var third = issues[2];
                bool hasAny = await context.Images.AnyAsync(i => i.MaintenanceIssueId == third.MaintenanceIssueId);
                if (!hasAny || forceSeed)
                {
                    var seedImagesPath = Path.Combine(Directory.GetCurrentDirectory(), "SeedImages", "Maintenance");
                    var files = Directory.Exists(seedImagesPath) ?
                        Directory.GetFiles(seedImagesPath, "*.jpg") : Array.Empty<string>();

                    foreach (var path in files.Take(1)) // add one more image for demo
                    {
                        var img = new Image
                        {
                            MaintenanceIssueId = third.MaintenanceIssueId,
                            ImageData = await File.ReadAllBytesAsync(path),
                            ContentType = "image/jpeg",
                            FileName = Path.GetFileName(path),
                            DateUploaded = DateTime.UtcNow
                        };
                        await context.Images.AddAsync(img);
                        updates++;
                    }
                }
            }

            if (updates > 0)
            {
                await context.SaveChangesAsync();
            }

            logger?.LogInformation("[{Seeder}] Done. Enhanced {Count} maintenance items.", Name, updates);
        }
    }
}
