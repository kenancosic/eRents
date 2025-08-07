using eRents.Features.LookupManagement.Models;
using FluentValidation;

namespace eRents.Features.LookupManagement.Validators
{
    /// <summary>
    /// Validator for amenity request data
    /// </summary>
    public class AmenityRequestValidator : AbstractValidator<AmenityRequest>
    {
        public AmenityRequestValidator()
        {
            RuleFor(x => x.AmenityName)
                .NotEmpty()
                .WithMessage("Amenity name is required.")
                .MaximumLength(50)
                .WithMessage("Amenity name cannot exceed 50 characters.")
                .Must(BeValidAmenityName)
                .WithMessage("Amenity name contains invalid characters or words.");
        }

        private static bool BeValidAmenityName(string amenityName)
        {
            if (string.IsNullOrWhiteSpace(amenityName))
                return false;

            // Check for basic validation - no excessive whitespace, reasonable characters
            var trimmed = amenityName.Trim();
            
            // Must not be empty after trimming
            if (string.IsNullOrEmpty(trimmed))
                return false;

            // Must not contain multiple consecutive spaces
            if (trimmed.Contains("  "))
                return false;

            // Must contain at least some alphabetic characters
            if (!trimmed.Any(char.IsLetter))
                return false;

            return true;
        }
    }
}