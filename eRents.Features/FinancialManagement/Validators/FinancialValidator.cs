using eRents.Features.FinancialManagement.DTOs;
using FluentValidation;

namespace eRents.Features.FinancialManagement.Validators;

/// <summary>
/// Validator for payment requests
/// </summary>
public class PaymentRequestValidator : AbstractValidator<PaymentRequest>
{
    private static readonly string[] ValidCurrencies = { "BAM", "EUR", "USD" };
    private static readonly string[] ValidPaymentMethods = { "PayPal", "CreditCard", "BankTransfer", "Cash" };

    public PaymentRequestValidator()
    {
        RuleFor(x => x.BookingId)
            .GreaterThan(0)
            .WithMessage("Valid booking ID is required")
            .When(x => x.BookingId.HasValue);

        RuleFor(x => x.PropertyId)
            .GreaterThan(0)
            .WithMessage("Valid property ID is required");

        RuleFor(x => x.Amount)
            .GreaterThan(0)
            .WithMessage("Amount must be greater than 0")
            .LessThanOrEqualTo(100000)
            .WithMessage("Amount cannot exceed 100,000");

        RuleFor(x => x.Currency)
            .NotEmpty()
            .WithMessage("Currency is required")
            .Must(BeValidCurrency)
            .WithMessage($"Currency must be one of: {string.Join(", ", ValidCurrencies)}");

        RuleFor(x => x.PaymentMethod)
            .NotEmpty()
            .WithMessage("Payment method is required")
            .Must(BeValidPaymentMethod)
            .WithMessage($"Payment method must be one of: {string.Join(", ", ValidPaymentMethods)}");

        RuleFor(x => x.ReturnUrl)
            .Must(BeValidUrl)
            .WithMessage("Return URL must be a valid URL")
            .When(x => !string.IsNullOrEmpty(x.ReturnUrl));

        RuleFor(x => x.CancelUrl)
            .Must(BeValidUrl)
            .WithMessage("Cancel URL must be a valid URL")
            .When(x => !string.IsNullOrEmpty(x.CancelUrl));
    }

    private static bool BeValidCurrency(string currency)
    {
        return ValidCurrencies.Contains(currency, StringComparer.OrdinalIgnoreCase);
    }

    private static bool BeValidPaymentMethod(string paymentMethod)
    {
        return ValidPaymentMethods.Contains(paymentMethod, StringComparer.OrdinalIgnoreCase);
    }

    private static bool BeValidUrl(string? url)
    {
        if (string.IsNullOrEmpty(url)) return false;
        return Uri.TryCreate(url, UriKind.Absolute, out var uriResult) &&
               (uriResult.Scheme == Uri.UriSchemeHttp || uriResult.Scheme == Uri.UriSchemeHttps);
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