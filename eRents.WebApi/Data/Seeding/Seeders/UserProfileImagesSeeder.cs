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
    /// Ensures each baseline user has a small placeholder profile image.
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
                Directory.GetFiles(userImagesPath, "*.png").ToArray() : 
                new string[0];
            
            for (int i = 0; i < Math.Min(users.Count, profileImages.Length); i++)
            {
                var user = users[i];
                var imagePath = profileImages[i];
                var imageData = await File.ReadAllBytesAsync(imagePath);
                var contentType = "image/png"; // All user images are png
                
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
            }

            await context.SaveChangesAsync();
            logger?.LogInformation("[{Seeder}] Done. Ensured {Count} user profile images.", Name, users.Count);
        }
    }
}
