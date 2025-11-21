using System;
using FluentValidation;
using eRents.Features.TenantManagement.Models;
using eRents.Domain.Models.Enums;
using eRents.Features.Core.Validation;

namespace eRents.Features.TenantManagement.Validators;

public class TenantRequestValidator : BaseValidator<TenantRequest>
{
    public TenantRequestValidator()
    {
        // UserId can be 0 for mobile/client requests - the service will populate it from auth context
        // Desktop landlords must provide a valid userId when creating tenant records
        RuleFor(x => x.UserId)
            .GreaterThanOrEqualTo(0).WithMessage("UserId cannot be negative.");

        RuleFor(x => x.TenantStatus)
            .IsInEnum().WithMessage("TenantStatus must be a valid enum value.");

        When(x => x.PropertyId.HasValue, () =>
        {
            RuleFor(x => x.PropertyId)
                .GreaterThan(0).WithMessage("PropertyId, when provided, must be greater than 0.");
        });

        // Date coherence: if both provided, End >= Start
        When(x => x.LeaseStartDate.HasValue && x.LeaseEndDate.HasValue, () =>
        {
            RuleFor(x => x)
                .Must(x => x.LeaseEndDate!.Value >= x.LeaseStartDate!.Value)
                .WithMessage("LeaseEndDate must be on or after LeaseStartDate.");
        });

        // Light-touch sanity for dates: no restriction if nulls (onboarding/pending allowed)
        When(x => x.LeaseStartDate.HasValue, () =>
        {
            RuleFor(x => x.LeaseStartDate!.Value)
                .LessThanOrEqualTo(DateOnly.FromDateTime(DateTime.UtcNow).AddYears(5))
                .WithMessage("LeaseStartDate is too far in the future.");
        });

        When(x => x.LeaseEndDate.HasValue, () =>
        {
            RuleFor(x => x.LeaseEndDate!.Value)
                .LessThanOrEqualTo(DateOnly.FromDateTime(DateTime.UtcNow).AddYears(10))
                .WithMessage("LeaseEndDate is too far in the future.");
        });

        // Optional: if status Active, prefer LeaseStartDate set (warning-level via validation)
        When(x => x.TenantStatus == TenantStatusEnum.Active, () =>
        {
            RuleFor(x => x.LeaseStartDate)
                .NotEmpty().WithMessage("LeaseStartDate should be set when TenantStatus is Active.");
        });
    }
}