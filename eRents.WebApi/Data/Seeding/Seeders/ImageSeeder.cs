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
    /// Seeds minimal property images. Adds a single cover image for first few properties
    /// that don't already have images. Uses small in-memory placeholder bytes.
    /// </summary>
    public class ImageSeeder : IDataSeeder
    {
        public int Order => 35; // after PropertiesSeeder (30), before Bookings/Reviews
        public string Name => nameof(ImageSeeder);

        public async Task SeedAsync(ERentsContext context, ILogger logger, bool forceSeed = false)
        {
            logger?.LogInformation("[{Seeder}] Starting...", Name);

            if (!forceSeed)
            {
                // If at least some images exist, skip to remain minimal
                var anyImages = await context.Images.AnyAsync(i => i.PropertyId != null);
                if (anyImages)
                {
                    logger?.LogInformation("[{Seeder}] Skipped (already present)", Name);
                    return;
                }
            }

            if (forceSeed)
            {
                await context.Images.IgnoreQueryFilters().ExecuteDeleteAsync();
            }

            // Take first 3-5 properties and ensure 1 cover image each
            var properties = await context.Properties
                .AsNoTracking()
                .OrderBy(p => p.PropertyId)
                .Select(p => new { p.PropertyId, p.Name })
                .Take(5)
                .ToListAsync();

            if (properties.Count == 0)
            {
                logger?.LogWarning("[{Seeder}] No properties found. Ensure PropertiesSeeder ran.", Name);
                return;
            }

            var imagesToAdd = new List<Image>();
            var seedImagesPath = Path.Combine(Directory.GetCurrentDirectory(), "SeedImages");
            var propertyImagesPath = Path.Combine(seedImagesPath, "Properties");
            var maintenanceImagesPath = Path.Combine(seedImagesPath, "Maintenance");
            
            var propertyImages = Directory.Exists(propertyImagesPath) ? 
                Directory.GetFiles(propertyImagesPath, "*.jpg").Concat(Directory.GetFiles(propertyImagesPath, "*.png")).ToArray() : 
                new string[0];
            var maintenanceImages = Directory.Exists(maintenanceImagesPath) ? 
                Directory.GetFiles(maintenanceImagesPath, "*.jpg").ToArray() : 
                new string[0];

            // Add property images
            for (int i = 0; i < Math.Min(properties.Count, propertyImages.Length); i++)
            {
                var p = properties[i];
                var hasImages = await context.Images.AnyAsync(img => img.PropertyId == p.PropertyId);
                if (hasImages) continue;

                var imagePath = propertyImages[i];
                var imageData = await File.ReadAllBytesAsync(imagePath);
                var contentType = imagePath.EndsWith(".png") ? "image/png" : "image/jpeg";

                imagesToAdd.Add(new Image
                {
                    PropertyId = p.PropertyId,
                    ImageData = imageData,
                    ContentType = contentType,
                    FileName = Path.GetFileName(imagePath),
                    DateUploaded = DateTime.UtcNow,
                    IsCover = true
                });
            }

            // Add maintenance issue images
            var maintenanceIssues = await context.MaintenanceIssues
                .AsNoTracking()
                .OrderBy(mi => mi.MaintenanceIssueId)
                .Take(2)
                .ToListAsync();
            for (int i = 0; i < Math.Min(maintenanceIssues.Count, maintenanceImages.Length); i++)
            {
                var issue = maintenanceIssues[i];
                var hasImages = await context.Images.AnyAsync(img => img.MaintenanceIssueId == issue.MaintenanceIssueId);
                if (hasImages) continue;

                var imagePath = maintenanceImages[i];
                var imageData = await File.ReadAllBytesAsync(imagePath);
                var contentType = "image/jpeg"; // All maintenance images are jpg

                imagesToAdd.Add(new Image
                {
                    MaintenanceIssueId = issue.MaintenanceIssueId,
                    ImageData = imageData,
                    ContentType = contentType,
                    FileName = Path.GetFileName(imagePath),
                    DateUploaded = DateTime.UtcNow
                });
            }

            if (imagesToAdd.Count > 0)
            {
                await context.Images.AddRangeAsync(imagesToAdd);
                await context.SaveChangesAsync();
            }

            logger?.LogInformation("[{Seeder}] Done. Added {Count} cover images.", Name, imagesToAdd.Count);
        }
    }
}
