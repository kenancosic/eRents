using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using eRents.Domain.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace eRents.WebApi.Data.Seeding.Seeders
{
    /// <summary>
    /// Seeds maintenance issue images by distributing available images across all maintenance issues.
    /// Assigns 1-2 random images per issue from SeedImages/Maintenance folder.
    /// Runs at Order 65, after MaintenanceIssuesSeeder (60) to ensure issues exist.
    /// </summary>
    public class MaintenanceImagesSeeder : IDataSeeder
    {
        public int Order => 65; // After MaintenanceIssuesSeeder (60)
        public string Name => nameof(MaintenanceImagesSeeder);

        public async Task SeedAsync(ERentsContext context, ILogger logger, bool forceSeed = false)
        {
            logger?.LogInformation("[{Seeder}] Starting...", Name);

            if (!forceSeed)
            {
                // If at least some maintenance images exist, skip
                var anyImages = await context.Images.AnyAsync(i => i.MaintenanceIssueId != null);
                if (anyImages)
                {
                    logger?.LogInformation("[{Seeder}] Skipped (already present)", Name);
                    return;
                }
            }

            if (forceSeed)
            {
                await context.Images.IgnoreQueryFilters()
                    .Where(i => i.MaintenanceIssueId != null)
                    .ExecuteDeleteAsync();
            }

            var imagesToAdd = new List<Image>();
            var seedImagesPath = Path.Combine(Directory.GetCurrentDirectory(), "SeedImages");
            var maintenanceImagesPath = Path.Combine(seedImagesPath, "Maintenance");
            
            var maintenanceImages = Directory.Exists(maintenanceImagesPath) ? 
                Directory.GetFiles(maintenanceImagesPath, "*.jpg")
                    .Concat(Directory.GetFiles(maintenanceImagesPath, "*.jpeg"))
                    .Concat(Directory.GetFiles(maintenanceImagesPath, "*.png"))
                    .ToArray() : 
                Array.Empty<string>();
            
            if (maintenanceImages.Length == 0)
            {
                logger?.LogWarning("[{Seeder}] No maintenance images found in {Path}. Skipping.", Name, maintenanceImagesPath);
                return;
            }

            logger?.LogInformation("[{Seeder}] Found {MaintCount} maintenance images", 
                Name, maintenanceImages.Length);

            // Get all maintenance issues to distribute images across
            var allIssues = await context.MaintenanceIssues
                .AsNoTracking()
                .OrderBy(mi => mi.MaintenanceIssueId)
                .Select(mi => new { mi.MaintenanceIssueId, mi.Title })
                .ToListAsync();

            if (allIssues.Count == 0)
            {
                logger?.LogWarning("[{Seeder}] No maintenance issues found. Ensure MaintenanceIssuesSeeder ran.", Name);
                return;
            }

            // Calculate how many images per issue (1-2 random images)
            int imagesPerIssue = maintenanceImages.Length > 0 ? 
                Math.Max(1, maintenanceImages.Length / allIssues.Count) : 1;
            imagesPerIssue = Math.Min(imagesPerIssue, 2); // Cap at 2 per issue
            imagesPerIssue = Math.Max(imagesPerIssue, 1); // Minimum 1 per issue

            logger?.LogInformation("[{Seeder}] Distributing images across {IssueCount} issues ({PerIssue} per issue)", 
                Name, allIssues.Count, imagesPerIssue);

            for (int i = 0; i < allIssues.Count; i++)
            {
                var issue = allIssues[i];
                var existingCount = await context.Images.CountAsync(img => img.MaintenanceIssueId == issue.MaintenanceIssueId);
                if (existingCount > 0) continue; // idempotent: skip if images already exist for this issue

                // Randomly select images for this issue (with replacement allowed)
                var random = new Random(issue.MaintenanceIssueId); // Seed with issue ID for consistency
                for (int k = 0; k < imagesPerIssue; k++)
                {
                    var imageIndex = random.Next(maintenanceImages.Length);
                    var imagePath = maintenanceImages[imageIndex];
                    var imageData = await File.ReadAllBytesAsync(imagePath);
                    var contentType = imagePath.EndsWith(".png", StringComparison.OrdinalIgnoreCase) 
                        ? "image/png" 
                        : "image/jpeg";

                    imagesToAdd.Add(new Image
                    {
                        MaintenanceIssueId = issue.MaintenanceIssueId,
                        ImageData = imageData,
                        ContentType = contentType,
                        FileName = Path.GetFileName(imagePath),
                        DateUploaded = DateTime.UtcNow,
                        IsCover = false // Maintenance images don't have a cover concept
                    });
                }
            }

            if (imagesToAdd.Count > 0)
            {
                await context.Images.AddRangeAsync(imagesToAdd);
                await context.SaveChangesAsync();
            }

            logger?.LogInformation("[{Seeder}] Done. Added {Count} maintenance images across {IssueCount} issues.", 
                Name, imagesToAdd.Count, allIssues.Count);
        }
    }
}
