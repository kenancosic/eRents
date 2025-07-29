using FluentValidation;
using System.Linq.Expressions;

namespace eRents.Features.Shared.Validation;

/// <summary>
/// Base validator class that provides common validation rules
/// to reduce boilerplate in FluentValidation validators
/// </summary>
public abstract class BaseEntityValidator<T> : AbstractValidator<T>
{
    /// <summary>
    /// Validates that an ID field is required and greater than 0
    /// </summary>
    /// <typeparam name="TProperty">Property type (int, long, etc.)</typeparam>
    /// <param name="expression">Property expression</param>
    /// <param name="fieldName">Display name for the field</param>
    protected void ValidateRequiredId<TProperty>(Expression<Func<T, TProperty>> expression, string fieldName)
    {
        RuleFor(expression)
            .Must(id => Convert.ToInt64(id) > 0)
            .WithMessage($"Valid {fieldName} is required and must be greater than 0");
    }

    /// <summary>
    /// Validates that a text field is required and within length limits
    /// </summary>
    /// <param name="expression">Property expression</param>
    /// <param name="fieldName">Display name for the field</param>
    /// <param name="maxLength">Maximum allowed length</param>
    /// <param name="minLength">Minimum required length (default: 1)</param>
    protected void ValidateRequiredText(Expression<Func<T, string>> expression, 
        string fieldName, int maxLength = 200, int minLength = 1)
    {
        RuleFor(expression)
            .NotEmpty()
            .WithMessage($"{fieldName} is required")
            .MinimumLength(minLength)
            .WithMessage($"{fieldName} must be at least {minLength} character(s)")
            .MaximumLength(maxLength)
            .WithMessage($"{fieldName} cannot exceed {maxLength} characters");
    }

    /// <summary>
    /// Validates that an optional text field is within length limits when provided
    /// </summary>
    /// <param name="expression">Property expression</param>
    /// <param name="fieldName">Display name for the field</param>
    /// <param name="maxLength">Maximum allowed length</param>
    protected void ValidateOptionalText(Expression<Func<T, string?>> expression, 
        string fieldName, int maxLength = 1000)
    {
        RuleFor(expression)
            .MaximumLength(maxLength)
            .WithMessage($"{fieldName} cannot exceed {maxLength} characters")
            .When(x => !string.IsNullOrEmpty(expression.Compile()(x)));
    }

    /// <summary>
    /// Validates that an email field is required and properly formatted
    /// </summary>
    /// <param name="expression">Property expression</param>
    /// <param name="fieldName">Display name for the field</param>
    protected void ValidateRequiredEmail(Expression<Func<T, string>> expression, string fieldName = "Email")
    {
        RuleFor(expression)
            .NotEmpty()
            .WithMessage($"{fieldName} is required")
            .EmailAddress()
            .WithMessage($"Valid {fieldName} address is required")
            .MaximumLength(254) // RFC 5321 limit
            .WithMessage($"{fieldName} cannot exceed 254 characters");
    }

    /// <summary>
    /// Validates that an optional email field is properly formatted when provided
    /// </summary>
    /// <param name="expression">Property expression</param>
    /// <param name="fieldName">Display name for the field</param>
    protected void ValidateOptionalEmail(Expression<Func<T, string?>> expression, string fieldName = "Email")
    {
        RuleFor(expression)
            .EmailAddress()
            .WithMessage($"Valid {fieldName} address is required")
            .MaximumLength(254)
            .WithMessage($"{fieldName} cannot exceed 254 characters")
            .When(x => !string.IsNullOrEmpty(expression.Compile()(x)));
    }

    /// <summary>
    /// Validates that a positive decimal value is required and within range
    /// </summary>
    /// <param name="expression">Property expression</param>
    /// <param name="fieldName">Display name for the field</param>
    /// <param name="minValue">Minimum allowed value</param>
    /// <param name="maxValue">Maximum allowed value</param>
    protected void ValidateRequiredPositiveDecimal(Expression<Func<T, decimal>> expression, 
        string fieldName, decimal minValue = 0.01m, decimal maxValue = 999999.99m)
    {
        RuleFor(expression)
            .GreaterThanOrEqualTo(minValue)
            .WithMessage($"{fieldName} must be at least {minValue}")
            .LessThanOrEqualTo(maxValue)
            .WithMessage($"{fieldName} cannot exceed {maxValue}");
    }

    /// <summary>
    /// Validates that a positive integer value is required and within range
    /// </summary>
    /// <param name="expression">Property expression</param>
    /// <param name="fieldName">Display name for the field</param>
    /// <param name="minValue">Minimum allowed value</param>
    /// <param name="maxValue">Maximum allowed value</param>
    protected void ValidateRequiredPositiveInt(Expression<Func<T, int>> expression, 
        string fieldName, int minValue = 1, int maxValue = int.MaxValue)
    {
        RuleFor(expression)
            .GreaterThanOrEqualTo(minValue)
            .WithMessage($"{fieldName} must be at least {minValue}")
            .LessThanOrEqualTo(maxValue)
            .WithMessage($"{fieldName} cannot exceed {maxValue}");
    }

    /// <summary>
    /// Validates that a date is required and within a reasonable range
    /// </summary>
    /// <param name="expression">Property expression</param>
    /// <param name="fieldName">Display name for the field</param>
    /// <param name="minDate">Minimum allowed date (default: today)</param>
    /// <param name="maxDate">Maximum allowed date (default: 10 years from now)</param>
    protected void ValidateRequiredDate(Expression<Func<T, DateTime>> expression, 
        string fieldName, DateTime? minDate = null, DateTime? maxDate = null)
    {
        var min = minDate ?? DateTime.Today;
        var max = maxDate ?? DateTime.Today.AddYears(10);

        RuleFor(expression)
            .GreaterThanOrEqualTo(min)
            .WithMessage($"{fieldName} must be {min:yyyy-MM-dd} or later")
            .LessThanOrEqualTo(max)
            .WithMessage($"{fieldName} must be {max:yyyy-MM-dd} or earlier");
    }

    /// <summary>
    /// Validates that end date is after start date
    /// </summary>
    /// <param name="startDateExpression">Start date property expression</param>
    /// <param name="endDateExpression">End date property expression</param>
    /// <param name="startFieldName">Display name for start date field</param>
    /// <param name="endFieldName">Display name for end date field</param>
    protected void ValidateDateRange(Expression<Func<T, DateTime>> startDateExpression,
        Expression<Func<T, DateTime>> endDateExpression,
        string startFieldName = "Start date", string endFieldName = "End date")
    {
        RuleFor(endDateExpression)
            .GreaterThan(startDateExpression)
            .WithMessage($"{endFieldName} must be after {startFieldName}");
    }

    /// <summary>
    /// Validates that end date is after start date (nullable version)
    /// </summary>
    /// <param name="startDateExpression">Start date property expression</param>
    /// <param name="endDateExpression">End date property expression</param>
    /// <param name="startFieldName">Display name for start date field</param>
    /// <param name="endFieldName">Display name for end date field</param>
    protected void ValidateOptionalDateRange(Expression<Func<T, DateTime?>> startDateExpression,
        Expression<Func<T, DateTime?>> endDateExpression,
        string startFieldName = "Start date", string endFieldName = "End date")
    {
        RuleFor(endDateExpression)
            .GreaterThan(startDateExpression)
            .WithMessage($"{endFieldName} must be after {startFieldName}")
            .When(x => startDateExpression.Compile()(x).HasValue && endDateExpression.Compile()(x).HasValue);
    }

    /// <summary>
    /// Validates that a value is in an allowed list
    /// </summary>
    /// <typeparam name="TProperty">Property type</typeparam>
    /// <param name="expression">Property expression</param>
    /// <param name="allowedValues">List of allowed values</param>
    /// <param name="fieldName">Display name for the field</param>
    protected void ValidateAllowedValues<TProperty>(Expression<Func<T, TProperty>> expression,
        IEnumerable<TProperty> allowedValues, string fieldName)
    {
        var allowedList = allowedValues.ToList();
        var allowedString = string.Join(", ", allowedList);

        RuleFor(expression)
            .Must(value => allowedList.Contains(value))
            .WithMessage($"{fieldName} must be one of: {allowedString}");
    }

    /// <summary>
    /// Validates that an optional value is in an allowed list when provided
    /// </summary>
    /// <typeparam name="TProperty">Property type</typeparam>
    /// <param name="expression">Property expression</param>
    /// <param name="allowedValues">List of allowed values</param>
    /// <param name="fieldName">Display name for the field</param>
    protected void ValidateOptionalAllowedValues<TProperty>(Expression<Func<T, TProperty?>> expression,
        IEnumerable<TProperty> allowedValues, string fieldName)
        where TProperty : struct
    {
        var allowedList = allowedValues.ToList();
        var allowedString = string.Join(", ", allowedList);

        RuleFor(expression)
            .Must(value => !value.HasValue || allowedList.Contains(value.Value))
            .WithMessage($"{fieldName} must be one of: {allowedString}")
            .When(x => expression.Compile()(x).HasValue);
    }
}
