using FluentValidation;
using eRents.Features.AuthManagement.Models;
using eRents.Features.Core.Validation;

namespace eRents.Features.AuthManagement.Validators;

/// <summary>
/// Validator for login requests
/// </summary>
public sealed class LoginRequestValidator : BaseValidator<LoginRequest>
{
    public LoginRequestValidator()
    {
        // Require either Username or Email
        RuleFor(x => x)
            .Must(x => !string.IsNullOrWhiteSpace(x.Username) || !string.IsNullOrWhiteSpace(x.Email))
            .WithMessage("Either username or email must be provided");

        // If Username provided, validate it
        When(x => !string.IsNullOrWhiteSpace(x.Username), () =>
        {
            RuleFor(x => x.Username!)
                .NotEmpty().WithMessage("Username is required when email is not provided")
                .Length(3, 100).WithMessage("Username must be between 3 and 100 characters");
        });

        // If Email provided, validate it
        When(x => !string.IsNullOrWhiteSpace(x.Email), () =>
        {
            RuleFor(x => x.Email!)
                .NotEmpty().WithMessage("Email is required when username is not provided")
                .EmailAddress().WithMessage("A valid email address is required");
        });

        RuleFor(x => x.Password)
            .NotEmpty().WithMessage("Password is required")
            .Length(6, 100).WithMessage("Password must be between 6 and 100 characters");
    }
}