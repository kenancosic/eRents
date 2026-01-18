using FluentValidation;
using eRents.Features.Core.Validation;
using eRents.Features.UserManagement.Models;

namespace eRents.Features.UserManagement.Validators;

/// <summary>
/// Validator for change password requests with strong password requirements
/// </summary>
public sealed class ChangePasswordRequestValidator : BaseValidator<ChangePasswordRequest>
{
    public ChangePasswordRequestValidator()
    {
        RuleFor(x => x.OldPassword)
            .NotEmpty().WithMessage("Current password is required");

        RuleFor(x => x.NewPassword)
            .NotEmpty().WithMessage("New password is required")
            .Length(8, 100).WithMessage("Password must be between 8 and 100 characters")
            .Matches(@"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]")
            .WithMessage("Password must contain at least one lowercase letter, one uppercase letter, one digit, and one special character (@$!%*?&)");

        RuleFor(x => x.ConfirmPassword)
            .NotEmpty().WithMessage("Password confirmation is required")
            .Equal(x => x.NewPassword).WithMessage("Passwords do not match");
    }
}
