using FluentValidation;
using eRents.Features.PropertyManagement.Models;
using eRents.Features.Core.Validation;

namespace eRents.Features.PropertyManagement.Validators;

public sealed class PropertyRequestValidator : BaseValidator<PropertyRequest>
{
    public PropertyRequestValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage("Name is required")
            .MaximumLength(100).WithMessage("Name must not exceed 100 characters");

        RuleFor(x => x.Price)
            .GreaterThan(0).WithMessage("Price must be greater than 0");

        RuleFor(x => x.Currency)
            .NotEmpty().WithMessage("Currency is required")
            .MaximumLength(10);

        // Optional: light constraints on address fields
        RuleFor(x => x.StreetLine1).MaximumLength(255);
        RuleFor(x => x.StreetLine2).MaximumLength(255);
        RuleFor(x => x.City).MaximumLength(100);
        RuleFor(x => x.State).MaximumLength(100);
        RuleFor(x => x.Country).MaximumLength(100);
        RuleFor(x => x.PostalCode).MaximumLength(20);

        RuleFor(x => x.Description).MaximumLength(1000);
    }
}