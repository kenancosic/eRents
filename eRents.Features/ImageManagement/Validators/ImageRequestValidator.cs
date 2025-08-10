using System;
using System.Text.RegularExpressions;
using eRents.Features.Core.Validation;
using eRents.Features.ImageManagement.Models;
using FluentValidation;

namespace eRents.Features.ImageManagement.Validators;

public class ImageRequestValidator : BaseValidator<ImageRequest>
{
    public ImageRequestValidator()
    {
        RuleFor(x => new { x.PropertyId, x.MaintenanceIssueId })
            .Must(link => link.PropertyId.HasValue || link.MaintenanceIssueId.HasValue)
            .WithMessage("At least one of PropertyId or MaintenanceIssueId must be provided.");

        RuleFor(x => x.FileName)
            .NotEmpty().WithMessage("FileName is required.")
            .MaximumLength(255).WithMessage("FileName must not exceed 255 characters.");

        RuleFor(x => x.ContentType)
            .NotEmpty().WithMessage("ContentType is required.")
            .Must(ct => ct.StartsWith("image/", StringComparison.OrdinalIgnoreCase))
            .WithMessage("ContentType must start with 'image/'.");

        RuleFor(x => x.Width)
            .GreaterThan(0).When(x => x.Width.HasValue)
            .WithMessage("Width must be greater than 0.");

        RuleFor(x => x.Height)
            .GreaterThan(0).When(x => x.Height.HasValue)
            .WithMessage("Height must be greater than 0.");

        RuleFor(x => x.FileSizeBytes)
            .GreaterThanOrEqualTo(0).When(x => x.FileSizeBytes.HasValue)
            .WithMessage("FileSizeBytes must be greater than or equal to 0.");

        // If ImageData provided, optionally enforce a max length guard (configurable later).
        RuleFor(x => x.ImageData)
            .NotNull().WithMessage("ImageData is required.")
            .Must(data => data.Length > 0)
            .WithMessage("ImageData cannot be empty.")
            // Placeholder for max size rule; can be made configurable later.
            .Must(data => data.Length <= 20 * 1024 * 1024)
            .WithMessage("ImageData exceeds the maximum allowed size of 20 MB.");

        RuleFor(x => x.DateUploaded)
            .Must(d => d == null || d.Value <= DateTime.UtcNow.AddMinutes(5))
            .WithMessage("DateUploaded cannot be far in the future.");
    }
}