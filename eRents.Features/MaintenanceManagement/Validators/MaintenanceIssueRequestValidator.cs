using FluentValidation;
using eRents.Features.MaintenanceManagement.Models;

namespace eRents.Features.MaintenanceManagement.Validators
{
    public class MaintenanceIssueRequestValidator : AbstractValidator<MaintenanceIssueRequest>
    {
        public MaintenanceIssueRequestValidator()
        {
            RuleFor(x => x.PropertyId)
                .GreaterThan(0).WithMessage("Property is required");

            RuleFor(x => x.Title)
                .NotEmpty().WithMessage("Title is required")
                .MaximumLength(200).WithMessage("Title cannot exceed 200 characters");

            RuleFor(x => x.Priority)
                .NotNull().WithMessage("Priority is required");

            RuleFor(x => x.Status)
                .NotNull().WithMessage("Status is required");

            RuleFor(x => x.ReportedByUserId)
                .GreaterThan(0).WithMessage("Reported by user is required");
        }
    }
}
