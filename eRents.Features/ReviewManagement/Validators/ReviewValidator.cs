using eRents.Features.ReviewManagement.DTOs;
using FluentValidation;

namespace eRents.Features.ReviewManagement.Validators;

/// <summary>
/// Comprehensive validator for review requests
/// Handles validation for creating and updating reviews
/// </summary>
public class ReviewValidator : AbstractValidator<ReviewRequest>
{
    public ReviewValidator()
    {
        RuleFor(x => x.PropertyId)
            .GreaterThan(0)
            .WithMessage("Valid property ID is required");

        RuleFor(x => x.BookingId)
            .GreaterThan(0)
            .WithMessage("Valid booking ID is required")
            .When(x => x.BookingId.HasValue);

        RuleFor(x => x.Description)
            .NotEmpty()
            .WithMessage("Review description is required")
            .MaximumLength(2000)
            .WithMessage("Review description cannot exceed 2000 characters")
            .MinimumLength(10)
            .WithMessage("Review description must be at least 10 characters");

        RuleFor(x => x.StarRating)
            .InclusiveBetween(1.0, 5.0)
            .WithMessage("Star rating must be between 1 and 5");
    }
}

 