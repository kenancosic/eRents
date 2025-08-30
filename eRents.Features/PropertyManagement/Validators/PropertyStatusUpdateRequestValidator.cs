using FluentValidation;
using eRents.Features.PropertyManagement.Models;
using eRents.Features.Core.Validation;
using eRents.Domain.Models.Enums;

namespace eRents.Features.PropertyManagement.Validators;

public sealed class PropertyStatusUpdateRequestValidator : BaseValidator<PropertyStatusUpdateRequest>
{
    public PropertyStatusUpdateRequestValidator()
    {
        // Status is required
        RuleFor(x => x.Status)
            .NotNull().WithMessage("Status is required");

        // When status is Unavailable, validate date range logic
        When(x => x.Status == PropertyStatusEnum.Unavailable, () =>
        {
            // UnavailableFrom is optional - if null, it will default to today
            // UnavailableTo is optional - if null, it means indefinite
            RuleFor(x => x)
                .Must(x => !x.UnavailableFrom.HasValue || !x.UnavailableTo.HasValue || x.UnavailableFrom <= x.UnavailableTo)
                .When(x => x.UnavailableFrom.HasValue && x.UnavailableTo.HasValue)
                .WithMessage("Unavailable start date must be before or equal to end date");
        });

        // When status is not Unavailable, date range should be null
        When(x => x.Status != PropertyStatusEnum.Unavailable, () =>
        {
            RuleFor(x => x.UnavailableFrom)
                .Null().WithMessage("Unavailable dates should only be specified when setting status to Unavailable");
                
            RuleFor(x => x.UnavailableTo)
                .Null().WithMessage("Unavailable dates should only be specified when setting status to Unavailable");
        });
    }
}
