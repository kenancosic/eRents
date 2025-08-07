using FluentValidation;
using eRents.Features.ReviewManagement.Models;
using eRents.Domain.Models.Enums;
using eRents.Features.Core.Validation;

namespace eRents.Features.ReviewManagement.Validators;

public class ReviewRequestValidator : BaseValidator<ReviewRequest>
{
    public ReviewRequestValidator()
    {
        RuleFor(x => x.ReviewType)
            .IsInEnum().WithMessage("ReviewType is required and must be valid.");

        // Basic ID sanity checks
        When(x => x.PropertyId.HasValue, () =>
        {
            RuleFor(x => x.PropertyId).GreaterThan(0);
        });

        When(x => x.ReviewerId.HasValue, () =>
        {
            RuleFor(x => x.ReviewerId).GreaterThan(0);
        });

        When(x => x.RevieweeId.HasValue, () =>
        {
            RuleFor(x => x.RevieweeId).GreaterThan(0);
        });

        When(x => x.BookingId.HasValue, () =>
        {
            RuleFor(x => x.BookingId).GreaterThan(0);
        });

        When(x => x.ParentReviewId.HasValue, () =>
        {
            RuleFor(x => x.ParentReviewId).GreaterThan(0);
        });

        // Star rating (when provided) must be within 0..5 supporting one decimal
        When(x => x.StarRating.HasValue, () =>
        {
            RuleFor(x => x.StarRating!.Value)
                .InclusiveBetween(0m, 5m)
                .WithMessage("StarRating must be between 0 and 5.");
        });

        // Branch: Reply vs Original
        When(x => !x.ParentReviewId.HasValue, () =>
        {
            // Original review
            // For property review: PropertyId required, RevieweeId optional (null)
            When(x => x.ReviewType == ReviewType.PropertyReview, () =>
            {
                RuleFor(x => x.PropertyId)
                    .NotNull().WithMessage("PropertyId is required for PropertyReview.");
            });

            // For tenant review: RevieweeId required
            When(x => x.ReviewType == ReviewType.TenantReview, () =>
            {
                RuleFor(x => x.RevieweeId)
                    .NotNull().WithMessage("RevieweeId is required for TenantReview.");
            });

            // For original reviews, BookingId if provided must be > 0 (already covered above).
            // Allow StarRating to be null; if provided, it's validated by the range rule above.
        });

        When(x => x.ParentReviewId.HasValue, () =>
        {
            // Reply
            // Description should not be empty for replies
            RuleFor(x => x.Description)
                .NotEmpty().WithMessage("Description is required for replies.");

            // Replies may omit rating; if provided still must be within 0..5 (covered above)
        });
    }
}