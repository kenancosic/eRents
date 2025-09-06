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
    /// Seeds a minimal set of property reviews.
    /// Depends on Users and Properties baseline existing.
    /// </summary>
    public class ReviewsSeeder : IDataSeeder
    {
        public int Order => 50; // after BookingsSeeder
        public string Name => nameof(ReviewsSeeder);

        public async Task SeedAsync(ERentsContext context, ILogger logger, bool forceSeed = false)
        {
            logger?.LogInformation("[{Seeder}] Starting...", Name);

            if (!forceSeed && await context.Reviews.AnyAsync())
            {
                logger?.LogInformation("[{Seeder}] Skipped (already present)", Name);
                return;
            }

            if (forceSeed)
            {
                await context.Reviews.IgnoreQueryFilters().ExecuteDeleteAsync();
            }

            var properties = await context.Properties.AsNoTracking().ToListAsync();
            var property = properties.FirstOrDefault();
            var reviewer1 = await context.Users.AsNoTracking().FirstOrDefaultAsync(u => u.Username == "mobile");
            var reviewer2 = await context.Users.AsNoTracking().FirstOrDefaultAsync(u => u.Username == "guestuser");
            var reviewer3 = await context.Users.AsNoTracking().FirstOrDefaultAsync(u => u.Username == "tenant_sarajevo");
            var reviewer4 = await context.Users.AsNoTracking().FirstOrDefaultAsync(u => u.Username == "tenant_mostar");
            var reviewer5 = await context.Users.AsNoTracking().FirstOrDefaultAsync(u => u.Username == "public_user_brcko");

            if (property == null || reviewer1 == null)
            {
                logger?.LogWarning("[{Seeder}] Prerequisites missing (property or reviewer).", Name);
                return;
            }

            var reviews = new List<Review>();
            
            // Review from mobile user
            var review1 = new Review
            {
                ReviewType = ReviewType.PropertyReview,
                PropertyId = property.PropertyId,
                ReviewerId = reviewer1.UserId,
                StarRating = 4.5m,
                Description = "Odličan smještaj, čistoća i lokacija su vrhunske."
            };
            reviews.Add(review1);

            // Review from guestuser
            if (reviewer2 != null)
            {
                var review2 = new Review
                {
                    ReviewType = ReviewType.PropertyReview,
                    PropertyId = property.PropertyId,
                    ReviewerId = reviewer2.UserId,
                    StarRating = 3.5m,
                    Description = "Dobar smještaj, ali može bolje grijanje."
                };
                reviews.Add(review2);
            }

            // Reviews for properties in different BH cities if we have enough properties
            if (properties.Count > 1 && reviewer3 != null)
            {
                var property2 = properties[1];
                var review3 = new Review
                {
                    ReviewType = ReviewType.PropertyReview,
                    PropertyId = property2.PropertyId,
                    ReviewerId = reviewer3.UserId,
                    StarRating = 5.0m,
                    Description = "Savršen smještaj u Sarajevu! Blizu Baščaršije i svih atrakcija."
                };
                reviews.Add(review3);
            }

            if (properties.Count > 2 && reviewer4 != null)
            {
                var property3 = properties[2];
                var review4 = new Review
                {
                    ReviewType = ReviewType.PropertyReview,
                    PropertyId = property3.PropertyId,
                    ReviewerId = reviewer4.UserId,
                    StarRating = 4.0m,
                    Description = "Odličan apartman u Mostaru, samo 5 minuta od Stari Most mosta."
                };
                reviews.Add(review4);
            }

            if (reviewer5 != null)
            {
                var review5 = new Review
                {
                    ReviewType = ReviewType.PropertyReview,
                    PropertyId = property.PropertyId,
                    ReviewerId = reviewer5.UserId,
                    StarRating = 4.8m,
                    Description = "Prekrasno iskustvo boravka u BH. Preporučujem svima koji posjećuju ovu predivnu zemlju."
                };
                reviews.Add(review5);
            }

            await context.Reviews.AddRangeAsync(reviews);
            await context.SaveChangesAsync();

            logger?.LogInformation("[{Seeder}] Done. Added {Count} reviews.", Name, reviews.Count);
        }
    }
}
