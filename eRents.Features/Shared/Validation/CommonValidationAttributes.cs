using System.ComponentModel.DataAnnotations;

namespace eRents.Features.Shared.Validation;

/// <summary>
/// Custom validation attribute for required ID fields (must be > 0)
/// </summary>
public class RequiredIdAttribute : ValidationAttribute
{
    public RequiredIdAttribute() 
    {
        ErrorMessage = "Valid {0} is required and must be greater than 0";
    }

    public override bool IsValid(object? value)
    {
        if (value == null) return false;

        if (value is int intValue)
            return intValue > 0;

        if (value is long longValue)
            return longValue > 0;

        return false;
    }

    public override string FormatErrorMessage(string name)
    {
        return string.Format(ErrorMessage ?? "Valid {0} is required", name);
    }
}

/// <summary>
/// Custom validation attribute for required text fields with maximum length
/// </summary>
public class RequiredTextAttribute : ValidationAttribute
{
    public int MaxLength { get; }

    public RequiredTextAttribute(int maxLength = 200)
    {
        MaxLength = maxLength;
        ErrorMessage = "{0} is required and cannot exceed {1} characters";
    }

    public override bool IsValid(object? value)
    {
        if (value == null) return false;

        var stringValue = value.ToString();
        if (string.IsNullOrWhiteSpace(stringValue)) return false;

        return stringValue.Length <= MaxLength;
    }

    public override string FormatErrorMessage(string name)
    {
        return string.Format(ErrorMessage ?? "{0} is required", name, MaxLength);
    }
}

/// <summary>
/// Custom validation attribute for optional text fields with maximum length
/// </summary>
public class OptionalTextAttribute : StringLengthAttribute
{
    public OptionalTextAttribute(int maxLength) : base(maxLength)
    {
        ErrorMessage = "{0} cannot exceed {1} characters";
    }

    public override bool IsValid(object? value)
    {
        // Allow null/empty for optional fields
        if (value == null) return true;

        var stringValue = value.ToString();
        if (string.IsNullOrEmpty(stringValue)) return true;

        return base.IsValid(value);
    }
}

/// <summary>
/// Custom validation attribute for required email fields
/// </summary>
public class RequiredEmailAttribute : ValidationAttribute
{
    private static readonly EmailAddressAttribute EmailValidator = new();

    public RequiredEmailAttribute()
    {
        ErrorMessage = "{0} is required and must be a valid email address";
    }

    public override bool IsValid(object? value)
    {
        if (value == null) return false;

        var stringValue = value.ToString();
        if (string.IsNullOrWhiteSpace(stringValue)) return false;

        return EmailValidator.IsValid(stringValue);
    }
}

/// <summary>
/// Custom validation attribute for required positive decimal values
/// </summary>
public class RequiredPositiveDecimalAttribute : ValidationAttribute
{
    public decimal MinValue { get; }
    public decimal MaxValue { get; }

    public RequiredPositiveDecimalAttribute(double minValue = 0.01, double maxValue = 999999.99)
    {
        MinValue = (decimal)minValue;
        MaxValue = (decimal)maxValue;
        ErrorMessage = "{0} is required and must be between {1} and {2}";
    }

    public override bool IsValid(object? value)
    {
        if (value == null) return false;

        if (value is decimal decimalValue)
            return decimalValue >= MinValue && decimalValue <= MaxValue;

        if (value is double doubleValue)
        {
            var convertedValue = (decimal)doubleValue;
            return convertedValue >= MinValue && convertedValue <= MaxValue;
        }

        if (value is float floatValue)
        {
            var convertedValue = (decimal)floatValue;
            return convertedValue >= MinValue && convertedValue <= MaxValue;
        }

        return false;
    }

    public override string FormatErrorMessage(string name)
    {
        return string.Format(ErrorMessage ?? "{0} is required", name, MinValue, MaxValue);
    }
}

/// <summary>
/// Custom validation attribute for required positive integer values
/// </summary>
public class RequiredPositiveIntAttribute : ValidationAttribute
{
    public int MinValue { get; }
    public int MaxValue { get; }

    public RequiredPositiveIntAttribute(int minValue = 1, int maxValue = int.MaxValue)
    {
        MinValue = minValue;
        MaxValue = maxValue;
        ErrorMessage = "{0} is required and must be between {1} and {2}";
    }

    public override bool IsValid(object? value)
    {
        if (value == null) return false;

        if (value is int intValue)
            return intValue >= MinValue && intValue <= MaxValue;

        return false;
    }

    public override string FormatErrorMessage(string name)
    {
        return string.Format(ErrorMessage ?? "{0} is required", name, MinValue, MaxValue);
    }
}

/// <summary>
/// Custom validation attribute for date ranges (start date must be before or equal to end date)
/// </summary>
public class DateRangeAttribute : ValidationAttribute
{
    public string StartDateProperty { get; }
    public string EndDateProperty { get; }

    public DateRangeAttribute(string startDateProperty, string endDateProperty)
    {
        StartDateProperty = startDateProperty;
        EndDateProperty = endDateProperty;
        ErrorMessage = "{0} must be before or equal to {1}";
    }

    protected override ValidationResult? IsValid(object? value, ValidationContext validationContext)
    {
        var startDateProperty = validationContext.ObjectType.GetProperty(StartDateProperty);
        var endDateProperty = validationContext.ObjectType.GetProperty(EndDateProperty);

        if (startDateProperty == null || endDateProperty == null)
            return ValidationResult.Success;

        var startDateValue = startDateProperty.GetValue(validationContext.ObjectInstance) as DateTime?;
        var endDateValue = endDateProperty.GetValue(validationContext.ObjectInstance) as DateTime?;

        if (startDateValue == null || endDateValue == null)
            return ValidationResult.Success;

        if (startDateValue > endDateValue)
        {
            return new ValidationResult(
                string.Format(ErrorMessage ?? "Date range is invalid", StartDateProperty, EndDateProperty),
                new[] { StartDateProperty, EndDateProperty });
        }

        return ValidationResult.Success;
    }
}
