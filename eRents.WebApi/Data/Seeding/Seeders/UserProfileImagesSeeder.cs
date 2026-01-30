using System;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using eRents.Domain.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace eRents.WebApi.Data.Seeding.Seeders
{
    /// <summary>
    /// Seeds user profile images by iterating through all available images in SeedImages/Users folder.
    /// Assigns profile images to all users without images, cycling through images using modulo to ensure
    /// all images get used even if there are more users than images.
    /// </summary>
    public class UserProfileImagesSeeder : IDataSeeder
    {
        public int Order => 25; // after UsersSeeder (20) and before PropertiesSeeder (30)
        public string Name => nameof(UserProfileImagesSeeder);

        public async Task SeedAsync(ERentsContext context, ILogger logger, bool forceSeed = false)
        {
            logger?.LogInformation("[{Seeder}] Starting...", Name);

            if (forceSeed)
            {
                // Only delete images that are linked as user profile images
                await context.Users.Where(u => u.ProfileImageId != null)
                    .ExecuteUpdateAsync(u => u.SetProperty(x => x.ProfileImageId, (int?)null));
                await context.Images.Where(i => context.Users.Any(u => u.ProfileImageId == i.ImageId))
                    .ExecuteDeleteAsync();
            }

            var users = await context.Users
                .Where(u => u.ProfileImageId == null)
                .ToListAsync();

            if (users.Count == 0)
            {
                logger?.LogInformation("[{Seeder}] Skipped (no users without profile images)", Name);
                return;
            }

            var seedImagesPath = Path.Combine(Directory.GetCurrentDirectory(), "SeedImages");
            var userImagesPath = Path.Combine(seedImagesPath, "Users");
            var profileImages = Directory.Exists(userImagesPath) ? 
                Directory.GetFiles(userImagesPath, "*.png")
                    .Concat(Directory.GetFiles(userImagesPath, "*.jpg"))
                    .Concat(Directory.GetFiles(userImagesPath, "*.jpeg"))
                    .ToArray() : 
                Array.Empty<string>();
            
            if (profileImages.Length == 0)
            {
                logger?.LogWarning("[{Seeder}] No profile images found in {Path}", Name, userImagesPath);
                return;
            }
            
            logger?.LogInformation("[{Seeder}] Found {ImgCount} profile images for {UserCount} users", 
                Name, profileImages.Length, users.Count);
            
            // Iterate through all users and cycle through images as needed
            for (int i = 0; i < users.Count; i++)
            {
                var user = users[i];
                // Use modulo to cycle through images if we have more users than images
                var imageIndex = i % profileImages.Length;
                var imagePath = profileImages[imageIndex];
                var imageData = await File.ReadAllBytesAsync(imagePath);
                var contentType = imagePath.EndsWith(".png", StringComparison.OrdinalIgnoreCase) 
                    ? "image/png" 
                    : "image/jpeg";
                
                var img = new Image
                {
                    ImageData = imageData,
                    ContentType = contentType,
                    FileName = Path.GetFileName(imagePath),
                    DateUploaded = DateTime.UtcNow,
                    IsCover = false
                };
                await context.Images.AddAsync(img);
                await context.SaveChangesAsync();
                user.ProfileImageId = img.ImageId;
                
                logger?.LogInformation("[{Seeder}] Assigned profile image {ImgIdx} to user {UserId}", 
                    Name, imageIndex + 1, user.UserId);
            }

            await context.SaveChangesAsync();
            logger?.LogInformation("[{Seeder}] Done. Assigned profile images to {Count} users.", Name, users.Count);
        }
    }
}
