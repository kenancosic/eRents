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
    /// Seeds property reviews across multiple properties from various tenants.
    /// Creates reviews with varied ratings (including some low ratings for testing).
    /// </summary>
    public class ReviewsSeeder : IDataSeeder
    {
        public int Order => 50; // after BookingsSeeder
        public string Name => nameof(ReviewsSeeder);

        private static readonly string[] PositiveReviews = new[]
        {
            "Odličan smještaj, čistoća i lokacija su vrhunske.",
            "Savršen smještaj! Blizu svih atrakcija.",
            "Prekrasno iskustvo boravka. Preporučujem svima.",
            "Vlasnik je vrlo ljubazan i uslužan. Stan je čist i udoban.",
            "Lokacija je idealna, sve je na dohvat ruke.",
            "Boravak je bio fantastičan, definitivno se vraćam.",
            "Sve je bilo kao na slikama, čak i bolje.",
            "Odlična vrijednost za novac. Preporučujem!",
            "Stan je prostran i dobro opremljen.",
            "Prijatan ambijent i tiha lokacija."
        };

        private static readonly string[] NegativeReviews = new[]
        {
            "Grijanje nije radilo kako treba, bilo je hladno.",
            "Čistoća nije bila na očekivanom nivou.",
            "Buka iz susjedstva je bila smetnja.",
            "Internet veza je bila nestabilna.",
            "Slike ne prikazuju realno stanje nekretnine."
        };

        private static readonly string[] TenantReviews = new[]
        {
            "Odličan stanar, sve je ostavio u savršenom stanju.",
            "Plaćanje uvijek na vrijeme, preporučujem kao stanara.",
            "Vrlo odgovoran i komunikativan stanar.",
            "Stan je bio u odličnom stanju nakon iseljenja.",
            "Pouzdan stanar, bez ikakvih problema tokom cijelog boravka.",
            "Savršen stanar, rado bih ga ponovno primio.",
            "Komunikacija je bila odlična, sve dogovore je poštovao."
        };

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
            var tenants = await context.Users.AsNoTracking()
                .Where(u => u.UserType == UserTypeEnum.Tenant)
                .Take(15)
                .ToListAsync();
            
            // Get completed bookings for verified reviews
            var completedBookings = await context.Bookings.AsNoTracking()
                .Where(b => b.Status == BookingStatusEnum.Completed || b.Status == BookingStatusEnum.Active)
                .ToListAsync();

            if (properties.Count == 0 || tenants.Count == 0)
            {
                logger?.LogWarning("[{Seeder}] Prerequisites missing (properties or tenants).", Name);
                return;
            }

            var reviews = new List<Review>();
            int tenantIndex = 0;

            // Create reviews for each property (2-3 reviews per property)
            foreach (var property in properties)
            {
                int reviewCount = Random.Shared.Next(2, 4);
                
                for (int i = 0; i < reviewCount && tenantIndex < tenants.Count * 2; i++)
                {
                    var reviewer = tenants[tenantIndex % tenants.Count];
                    tenantIndex++;

                    // 15% chance of a low rating (for testing negative flows)
                    bool isLowRating = Random.Shared.Next(100) < 15;
                    decimal rating = isLowRating 
                        ? (decimal)(Random.Shared.Next(15, 30) / 10.0) // 1.5 - 2.9
                        : (decimal)(Random.Shared.Next(35, 51) / 10.0); // 3.5 - 5.0

                    string description = isLowRating
                        ? NegativeReviews[Random.Shared.Next(NegativeReviews.Length)]
                        : PositiveReviews[Random.Shared.Next(PositiveReviews.Length)];

                    // Link to booking if reviewer has a completed booking at this property
                    var matchingBooking = completedBookings.FirstOrDefault(b => 
                        b.UserId == reviewer.UserId && b.PropertyId == property.PropertyId);

                    reviews.Add(new Review
                    {
                        ReviewType = ReviewType.PropertyReview,
                        PropertyId = property.PropertyId,
                        ReviewerId = reviewer.UserId,
                        BookingId = matchingBooking?.BookingId, // Verified stay if booking exists
                        StarRating = rating,
                        Description = description
                    });
                }
            }

            // Add tenant reviews (landlords reviewing tenants)
            var owners = await context.Users.AsNoTracking()
                .Where(u => u.UserType == UserTypeEnum.Owner)
                .Take(5)
                .ToListAsync();
            
            foreach (var booking in completedBookings.Take(5))
            {
                var property = properties.FirstOrDefault(p => p.PropertyId == booking.PropertyId);
                if (property == null) continue;
                
                var owner = owners.FirstOrDefault(o => o.UserId == property.OwnerId);
                if (owner == null) continue;
                
                var tenant = tenants.FirstOrDefault(t => t.UserId == booking.UserId);
                if (tenant == null) continue;

                // Owner reviews tenant
                reviews.Add(new Review
                {
                    ReviewType = ReviewType.TenantReview,
                    PropertyId = property.PropertyId,
                    ReviewerId = owner.UserId,
                    RevieweeId = tenant.UserId,
                    BookingId = booking.BookingId,
                    StarRating = (decimal)(Random.Shared.Next(38, 51) / 10.0), // 3.8 - 5.0
                    Description = TenantReviews[Random.Shared.Next(TenantReviews.Length)]
                });
            }

            await context.Reviews.AddRangeAsync(reviews);
            await context.SaveChangesAsync();

            logger?.LogInformation("[{Seeder}] Done. Added {Count} reviews across {PropertyCount} properties.", Name, reviews.Count, properties.Count);
        }
    }
}
