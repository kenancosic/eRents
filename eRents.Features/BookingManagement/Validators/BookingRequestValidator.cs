using FluentValidation;
using eRents.Features.BookingManagement.Models;
using eRents.Features.Core.Validation;

namespace eRents.Features.BookingManagement.Validators;

public class BookingRequestValidator : BaseValidator<BookingRequest>
{
    public BookingRequestValidator()
    {
        RuleFor(x => x.PropertyId)
            .GreaterThan(0).WithMessage("PropertyId must be greater than 0");

        RuleFor(x => x.StartDate)
            .NotEmpty().WithMessage("StartDate is required");

        RuleFor(x => x.EndDate)
            .Must((req, end) => end == null || end.Value >= req.StartDate)
            .WithMessage("EndDate must be greater than or equal to StartDate");

        RuleFor(x => x.TotalPrice)
            .GreaterThanOrEqualTo(0).WithMessage("TotalPrice must be greater than or equal to 0");

        RuleFor(x => x.PaymentMethod)
            .NotEmpty().WithMessage("PaymentMethod is required");

        RuleFor(x => x.Currency)
            .NotEmpty().WithMessage("Currency is required");

        // Business rule like MinimumStayDays will be validated in service (if needed).
    }
}