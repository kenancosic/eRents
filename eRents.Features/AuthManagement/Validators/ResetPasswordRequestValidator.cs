using FluentValidation;
using eRents.Features.AuthManagement.Models;
using eRents.Features.Core.Validation;

namespace eRents.Features.AuthManagement.Validators;

/// <summary>
/// Validator for reset password requests
/// </summary>
public sealed class ResetPasswordRequestValidator : BaseValidator<ResetPasswordRequest>
{
    public ResetPasswordRequestValidator()
    {
        RuleFor(x => x.Email)
            .NotEmpty().WithMessage("Email is required")
            .EmailAddress().WithMessage("Invalid email format")
            .MaximumLength(100).WithMessage("Email must not exceed 100 characters");

        RuleFor(x => x.ResetCode)
            .NotEmpty().WithMessage("Reset code is required");

        RuleFor(x => x.NewPassword)
            .NotEmpty().WithMessage("New password is required")
            .Length(8, 100).WithMessage("Password must be between 8 and 100 characters")
            .Matches(@"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]")
            .WithMessage("Password must contain at least one lowercase letter, one uppercase letter, one digit, and one special character");

        RuleFor(x => x.ConfirmPassword)
            .NotEmpty().WithMessage("Password confirmation is required")
            .Equal(x => x.NewPassword).WithMessage("Passwords do not match");
    }
}