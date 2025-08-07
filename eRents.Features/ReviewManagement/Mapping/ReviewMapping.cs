using Mapster;
using eRents.Domain.Models;
using eRents.Features.ReviewManagement.Models;

namespace eRents.Features.ReviewManagement.Mapping;

public static class ReviewMapping
{
    public static void Configure(TypeAdapterConfig config)
    {
        // Entity -> Response (projection-safe)
        config.NewConfig<Review, ReviewResponse>()
            .Map(d => d.ReviewId, s => s.ReviewId)
            .Map(d => d.ReviewType, s => s.ReviewType)
            .Map(d => d.PropertyId, s => s.PropertyId)
            .Map(d => d.RevieweeId, s => s.RevieweeId)
            .Map(d => d.ReviewerId, s => s.ReviewerId)
            .Map(d => d.Description, s => s.Description)
            .Map(d => d.StarRating, s => s.StarRating)
            .Map(d => d.BookingId, s => s.BookingId)
            .Map(d => d.ParentReviewId, s => s.ParentReviewId)
            .Map(d => d.CreatedAt, s => s.CreatedAt)
            .Map(d => d.CreatedBy, s => s.CreatedBy)
            .Map(d => d.UpdatedAt, s => s.UpdatedAt)
            // Note: RepliesCount optional; avoid .Count() in mapping to keep expression-safe.
            .Ignore(d => d.RepliesCount);

        // Request -> Entity (ignore identity/audit)
        config.NewConfig<ReviewRequest, Review>()
            .Ignore(d => d.ReviewId)
            .Ignore(d => d.CreatedAt)
            .Ignore(d => d.CreatedBy)
            .Ignore(d => d.UpdatedAt)
            .Map(d => d.ReviewType, s => s.ReviewType)
            .Map(d => d.PropertyId, s => s.PropertyId)
            .Map(d => d.RevieweeId, s => s.RevieweeId)
            .Map(d => d.ReviewerId, s => s.ReviewerId)
            .Map(d => d.Description, s => s.Description)
            .Map(d => d.StarRating, s => s.StarRating)
            .Map(d => d.BookingId, s => s.BookingId)
            .Map(d => d.ParentReviewId, s => s.ParentReviewId)
            .AfterMapping((src, dest) =>
            {
                // Normalize fields for replies vs originals if needed
                if (src.ParentReviewId.HasValue)
                {
                    // Replies typically do not carry StarRating; keep as provided (may be null)
                    // Ensure ReviewType stays as provided to support 'ResponseReview' if used
                }
                else
                {
                    // Originals may omit rating; semantics validated by validator/service
                }
            });
    }
}