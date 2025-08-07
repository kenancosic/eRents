using eRents.Features.Core.Validation;
using eRents.Features.PaymentManagement.Models;
using FluentValidation;

namespace eRents.Features.PaymentManagement.Validators;

public class PaymentRequestValidator : BaseValidator<PaymentRequest>
{
    public PaymentRequestValidator()
    {
        // Amount must be >= 0
        RuleFor(x => x.Amount)
            .GreaterThanOrEqualTo(0m)
            .WithMessage("Amount must be greater than or equal to 0.");

        // Currency required (non-empty)
        RuleFor(x => x.Currency)
            .NotEmpty()
            .WithMessage("Currency is required.");

        // PaymentMethod required (non-empty)
        RuleFor(x => x.PaymentMethod)
            .NotEmpty()
            .WithMessage("PaymentMethod is required.");

        // If PaymentType == "Refund", OriginalPaymentId must be provided and > 0
        RuleFor(x => x.OriginalPaymentId)
            .NotNull()
            .GreaterThan(0)
            .When(x => string.Equals(x.PaymentType, "Refund", System.StringComparison.OrdinalIgnoreCase))
            .WithMessage("OriginalPaymentId must be provided and greater than 0 for Refund payments.");

        // If OriginalPaymentId is set, PaymentType should be "Refund"
        RuleFor(x => x.PaymentType)
            .Must(pt => string.Equals(pt, "Refund", System.StringComparison.OrdinalIgnoreCase))
            .When(x => x.OriginalPaymentId.HasValue)
            .WithMessage("PaymentType must be 'Refund' when OriginalPaymentId is provided.");

        // ID sanity checks (> 0 when provided)
        RuleFor(x => x.TenantId)
            .GreaterThan(0)
            .When(x => x.TenantId.HasValue)
            .WithMessage("TenantId must be greater than 0 when provided.");

        RuleFor(x => x.PropertyId)
            .GreaterThan(0)
            .When(x => x.PropertyId.HasValue)
            .WithMessage("PropertyId must be greater than 0 when provided.");

        RuleFor(x => x.BookingId)
            .GreaterThan(0)
            .When(x => x.BookingId.HasValue)
            .WithMessage("BookingId must be greater than 0 when provided.");
    }
}