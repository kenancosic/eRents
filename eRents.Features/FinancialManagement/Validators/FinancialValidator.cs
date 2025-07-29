using eRents.Features.FinancialManagement.DTOs;
using FluentValidation;

namespace eRents.Features.FinancialManagement.Validators;

/// <summary>
/// Validator for payment requests
/// </summary>
using eRents.Features.Shared.Validation;

public class PaymentRequestValidator : BaseEntityValidator<PaymentRequest>
{
	public PaymentRequestValidator()
	{
		ValidateRequiredId(x => x.PropertyId, "Property ID");
		ValidateRequiredPositiveDecimal(x => x.Amount, "Amount");
	}
}

public class RefundRequestValidator : BaseEntityValidator<RefundRequest>
{
    public RefundRequestValidator()
    {
        ValidateRequiredId(x => x.OriginalPaymentId, "Original Payment ID");
        ValidateRequiredPositiveDecimal(x => x.Amount, "Amount");
        ValidateRequiredText(x => x.Reason, "Reason", 500);
        ValidateOptionalText(x => x.Notes, "Notes", 1000);
    }
}

/// <summary>
/// Validator for financial report requests
/// Note: This validates report generation parameters, not the response DTOs
/// </summary>
public class FinancialReportRequestValidator : AbstractValidator<object>
{
    public FinancialReportRequestValidator()
    {
        // This would be for report generation request parameters
        // Since FinancialReportResponse is a response DTO, we don't validate it
        // But if there were report request parameters, they would be validated here
    }
}

/// <summary>
/// Validator for financial summary requests
/// Note: This validates summary generation parameters, not the response DTOs
/// </summary>
public class FinancialSummaryRequestValidator : AbstractValidator<object>
{
    public FinancialSummaryRequestValidator()
    {
        // This would be for summary generation request parameters
        // Since FinancialSummaryResponse is a response DTO, we don't validate it
        // But if there were summary request parameters, they would be validated here
    }
}

/// <summary>
/// Generic validator for date range financial queries
/// Can be used for financial reports, summaries, and other date-based queries
/// </summary>
public class FinancialDateRangeValidator : AbstractValidator<(DateTime DateFrom, DateTime DateTo)>
{
    public FinancialDateRangeValidator()
    {
        RuleFor(x => x.DateFrom)
            .NotEmpty()
            .WithMessage("Start date is required")
            .LessThanOrEqualTo(DateTime.Today)
            .WithMessage("Start date cannot be in the future");

        RuleFor(x => x.DateTo)
            .NotEmpty()
            .WithMessage("End date is required")
            .GreaterThanOrEqualTo(x => x.DateFrom)
            .WithMessage("End date must be after or equal to start date")
            .LessThanOrEqualTo(DateTime.Today)
            .WithMessage("End date cannot be in the future");

        // Business rule: Report range shouldn't be more than 5 years
        RuleFor(x => x)
            .Must(HaveReasonableDateRange)
            .WithMessage("Date range cannot exceed 5 years");
    }

    private static bool HaveReasonableDateRange((DateTime DateFrom, DateTime DateTo) dateRange)
    {
        var duration = dateRange.DateTo - dateRange.DateFrom;
        return duration.TotalDays <= (365 * 5); // Max 5 years
    }
}

/// <summary>
/// Validator for property-specific financial queries
/// </summary>
public class PropertyFinancialQueryValidator : AbstractValidator<(int PropertyId, DateTime? DateFrom, DateTime? DateTo)>
{
    public PropertyFinancialQueryValidator()
    {
        RuleFor(x => x.PropertyId)
            .GreaterThan(0)
            .WithMessage("Valid property ID is required");

        RuleFor(x => x.DateFrom)
            .LessThanOrEqualTo(DateTime.Today)
            .WithMessage("Start date cannot be in the future")
            .When(x => x.DateFrom.HasValue);

        RuleFor(x => x.DateTo)
            .GreaterThanOrEqualTo(x => x.DateFrom)
            .WithMessage("End date must be after or equal to start date")
            .LessThanOrEqualTo(DateTime.Today)
            .WithMessage("End date cannot be in the future")
            .When(x => x.DateFrom.HasValue && x.DateTo.HasValue);

        // Business rule: Query range shouldn't be more than 10 years for property-specific queries
        RuleFor(x => x)
            .Must(HaveReasonableDateRange)
            .WithMessage("Date range cannot exceed 10 years")
            .When(x => x.DateFrom.HasValue && x.DateTo.HasValue);
    }

    private static bool HaveReasonableDateRange((int PropertyId, DateTime? DateFrom, DateTime? DateTo) query)
    {
        if (!query.DateFrom.HasValue || !query.DateTo.HasValue) return true;
        var duration = query.DateTo.Value - query.DateFrom.Value;
        return duration.TotalDays <= (365 * 10); // Max 10 years for property-specific queries
    }
} 