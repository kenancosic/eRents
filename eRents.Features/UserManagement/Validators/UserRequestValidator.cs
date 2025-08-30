using System;
using FluentValidation;
using eRents.Domain.Models.Enums;
using eRents.Features.Core.Validation;
using eRents.Features.UserManagement.Models;

namespace eRents.Features.UserManagement.Validators;

public sealed class UserRequestValidator : BaseValidator<UserRequest>
{
    public UserRequestValidator()
    {
        // Identity
        RuleFor(x => x.Username)
            .NotEmpty().WithMessage("Username is required.")
            .MaximumLength(50);

        RuleFor(x => x.Email)
            .NotEmpty().WithMessage("Email is required.")
            .EmailAddress().WithMessage("Email format is invalid.")
            .MaximumLength(100);

        RuleFor(x => x.FirstName)
            .MaximumLength(100);
        RuleFor(x => x.LastName)
            .MaximumLength(100);

        // Enum
        RuleFor(x => x.UserType)
            .IsInEnum().WithMessage("UserType must be a valid enum value.");

        // ProfileImageId, optional but if provided must be positive
        When(x => x.ProfileImageId.HasValue, () =>
        {
            RuleFor(x => x.ProfileImageId!.Value)
                .GreaterThan(0).WithMessage("ProfileImageId must be greater than 0 when provided.");
        });

        // Phone length sanity
        When(x => !string.IsNullOrWhiteSpace(x.PhoneNumber), () =>
        {
            RuleFor(x => x.PhoneNumber!)
                .MaximumLength(50);
        });

        // Address – light constraints
        RuleFor(x => x.StreetLine1).MaximumLength(255);
        RuleFor(x => x.StreetLine2).MaximumLength(255);
        RuleFor(x => x.City).MaximumLength(100);
        RuleFor(x => x.State).MaximumLength(100);
        RuleFor(x => x.Country).MaximumLength(100);
        RuleFor(x => x.PostalCode).MaximumLength(20);

        // Coordinates range if provided
        When(x => x.Latitude.HasValue, () =>
        {
            RuleFor(x => x.Latitude!.Value)
                .InclusiveBetween(-90m, 90m).WithMessage("Latitude must be between -90 and 90.");
        });

        When(x => x.Longitude.HasValue, () =>
        {
            RuleFor(x => x.Longitude!.Value)
                .InclusiveBetween(-180m, 180m).WithMessage("Longitude must be between -180 and 180.");
        });


        // DateOfBirth logical constraint (optional)
        When(x => x.DateOfBirth.HasValue, () =>
        {
            RuleFor(x => x.DateOfBirth!.Value)
                .LessThanOrEqualTo(DateOnly.FromDateTime(DateTime.UtcNow))
                .WithMessage("DateOfBirth cannot be in the future.");
        });

        // If profile is public, require at least City to be provided
        When(x => x.IsPublic == true, () =>
        {
            RuleFor(x => x.City)
                .NotEmpty().WithMessage("City is required when profile is public.");
        });
    }
}