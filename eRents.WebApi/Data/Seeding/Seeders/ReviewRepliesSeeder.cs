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
    /// Adds threaded replies to a couple of property reviews and seeds a landlord -> tenant review.
    /// </summary>
    public class ReviewRepliesSeeder : IDataSeeder
    {
        public int Order => 55; // After ReviewsSeeder (50)
        public string Name => nameof(ReviewRepliesSeeder);

        public async Task SeedAsync(ERentsContext context, ILogger logger, bool forceSeed = false)
        {
            logger?.LogInformation("[{Seeder}] Starting...", Name);

            if (forceSeed)
            {
                // Only delete threaded responses and tenant reviews added by this seeder
                await context.Reviews
                    .Where(r => r.ReviewType == ReviewType.ResponseReview || r.ReviewType == ReviewType.TenantReview)
                    .ExecuteDeleteAsync();
            }

            // 1) Add replies to a couple of property reviews
            var targetReviews = await context.Reviews
                .Where(r => r.ReviewType == ReviewType.PropertyReview && r.ParentReviewId == null)
                .OrderBy(r => r.ReviewId)
                .Take(2)
                .ToListAsync();

            int repliesAdded = 0;
            foreach (var parent in targetReviews)
            {
                bool hasReply = await context.Reviews.AnyAsync(r => r.ParentReviewId == parent.ReviewId);
                if (hasReply && !forceSeed) continue;

                var reply = new Review
                {
                    ReviewType = ReviewType.ResponseReview,
                    PropertyId = parent.PropertyId,
                    RevieweeId = parent.RevieweeId,
                    ReviewerId = null, // System/owner reply could be anonymous; keep null for demo
                    Description = "Hvala na povratnoj informaciji! Drago nam je da ste uživali u boravku.",
                    StarRating = null, // replies have no rating
                    BookingId = parent.BookingId,
                    ParentReviewId = parent.ReviewId
                };
                await context.Reviews.AddAsync(reply);
                repliesAdded++;
            }

            // 2) Add a landlord review of tenant for an ended/active booking
            // Pick a booking and infer owner/tenant
            var booking = await context.Bookings
                .Include(b => b.Property)
                .OrderBy(b => b.BookingId)
                .FirstOrDefaultAsync();

            if (booking != null)
            {
                // reviewee is the tenant user (booking.UserId)
                bool tenantReviewExists = await context.Reviews.AnyAsync(r =>
                    r.ReviewType == ReviewType.TenantReview && r.RevieweeId == booking.UserId && r.PropertyId == booking.PropertyId);

                if (!tenantReviewExists || forceSeed)
                {
                    var tenantReview = new Review
                    {
                        ReviewType = ReviewType.TenantReview,
                        PropertyId = booking.PropertyId,
                        RevieweeId = booking.UserId,
                        ReviewerId = booking.Property?.OwnerId,
                        Description = "Pouzdan i uredan stanar, preporuka za buduće najmove.",
                        StarRating = 5.0m,
                        BookingId = booking.BookingId
                    };
                    await context.Reviews.AddAsync(tenantReview);
                }
            }

            if (repliesAdded > 0)
            {
                await context.SaveChangesAsync();
            }
            else
            {
                // Still save if we added the tenant review
                await context.SaveChangesAsync();
            }

            logger?.LogInformation("[{Seeder}] Done. Added {Replies} replies and ensured tenant review.", Name, repliesAdded);
        }
    }
}
