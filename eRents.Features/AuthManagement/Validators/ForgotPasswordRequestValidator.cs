using FluentValidation;
using eRents.Features.AuthManagement.Models;
using eRents.Features.Core.Validation;

namespace eRents.Features.AuthManagement.Validators;

/// <summary>
/// Validator for forgot password requests
/// </summary>
public sealed class ForgotPasswordRequestValidator : BaseValidator<ForgotPasswordRequest>
{
    public ForgotPasswordRequestValidator()
    {
        RuleFor(x => x.Email)
            .NotEmpty().WithMessage("Email is required")
            .EmailAddress().WithMessage("Invalid email format")
            .MaximumLength(100).WithMessage("Email must not exceed 100 characters");
    }
}