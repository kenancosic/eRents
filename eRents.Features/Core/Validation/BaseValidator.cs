using FluentValidation;

namespace eRents.Features.Core.Validation
{
    /// <summary>
    /// Base validator class for request DTOs
    /// </summary>
    /// <typeparam name="T">The type of the request DTO</typeparam>
    public abstract class BaseValidator<T> : AbstractValidator<T>
    {
        protected BaseValidator()
        {
            // Common validation rules can be defined here
            // For example, setting up a default cascade mode
            RuleLevelCascadeMode = CascadeMode.Stop;
            ClassLevelCascadeMode = CascadeMode.Stop;
        }

        // Common validation rules can be added as protected methods
        // For example:
        protected IRuleBuilderOptions<T, string> ValidateName<TEntity>(IRuleBuilder<T, string> ruleBuilder)
        {
            return ruleBuilder
                .NotEmpty().WithMessage("{PropertyName} is required")
                .MaximumLength(100).WithMessage("{PropertyName} must not exceed 100 characters");
        }
    }
}
