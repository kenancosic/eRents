using eRents.Features.MaintenanceManagement.DTOs;
using FluentValidation;

namespace eRents.Features.MaintenanceManagement.Validators;

/// <summary>
/// Comprehensive validator for maintenance issue requests
/// Handles validation for creating and updating reactive maintenance issues
/// </summary>
public class MaintenanceIssueValidator : AbstractValidator<MaintenanceIssueRequest>
{
    private static readonly string[] ValidPriorities = { "Low", "Medium", "High", "Emergency" };

    public MaintenanceIssueValidator()
    {
        RuleFor(x => x.PropertyId)
            .GreaterThan(0)
            .WithMessage("Valid property ID is required");

        RuleFor(x => x.AssignedToUserId)
            .GreaterThan(0)
            .WithMessage("Valid assigned user ID is required")
            .When(x => x.AssignedToUserId.HasValue);

        RuleFor(x => x.Title)
            .NotEmpty()
            .WithMessage("Title is required")
            .MaximumLength(200)
            .WithMessage("Title cannot exceed 200 characters");

        RuleFor(x => x.Description)
            .MaximumLength(1000)
            .WithMessage("Description cannot exceed 1000 characters");

        RuleFor(x => x.Priority)
            .NotEmpty()
            .WithMessage("Priority is required")
            .Must(BeValidPriority)
            .WithMessage($"Priority must be one of: {string.Join(", ", ValidPriorities)}");

        RuleFor(x => x.Cost)
            .GreaterThanOrEqualTo(0)
            .WithMessage("Cost must be non-negative")
            .When(x => x.Cost.HasValue);

        RuleFor(x => x.Category)
            .MaximumLength(100)
            .WithMessage("Category cannot exceed 100 characters")
            .When(x => !string.IsNullOrEmpty(x.Category));

        RuleFor(x => x.ResolutionNotes)
            .MaximumLength(500)
            .WithMessage("Resolution notes cannot exceed 500 characters")
            .When(x => !string.IsNullOrEmpty(x.ResolutionNotes));
    }

    private static bool BeValidPriority(string priority)
    {
        return ValidPriorities.Contains(priority, StringComparer.OrdinalIgnoreCase);
    }
}

/// <summary>
/// Validator for maintenance status update requests
/// </summary>
public class MaintenanceStatusUpdateValidator : AbstractValidator<MaintenanceStatusUpdateRequest>
{
    private static readonly string[] ValidStatuses = { "Pending", "InProgress", "Completed", "Cancelled" };

    public MaintenanceStatusUpdateValidator()
    {
        RuleFor(x => x.Status)
            .NotEmpty()
            .WithMessage("Status is required")
            .Must(BeValidStatus)
            .WithMessage($"Status must be one of: {string.Join(", ", ValidStatuses)}");

        RuleFor(x => x.Cost)
            .GreaterThanOrEqualTo(0)
            .WithMessage("Cost must be non-negative")
            .When(x => x.Cost.HasValue);

        RuleFor(x => x.ResolvedAt)
            .LessThanOrEqualTo(DateTime.Now)
            .WithMessage("Resolved date cannot be in the future")
            .When(x => x.ResolvedAt.HasValue);

        RuleFor(x => x.ResolutionNotes)
            .MaximumLength(500)
            .WithMessage("Resolution notes cannot exceed 500 characters")
            .When(x => !string.IsNullOrEmpty(x.ResolutionNotes));

        // Business rule: Completed status requires resolution date
        RuleFor(x => x.ResolvedAt)
            .NotNull()
            .WithMessage("Resolved date is required when status is 'Completed'")
            .When(x => x.Status.Equals("Completed", StringComparison.OrdinalIgnoreCase));
    }

    private static bool BeValidStatus(string status)
    {
        return ValidStatuses.Contains(status, StringComparer.OrdinalIgnoreCase);
    }
}

/// <summary>
/// Validator for maintenance assignment requests
/// </summary>
public class AssignMaintenanceValidator : AbstractValidator<AssignMaintenanceRequest>
{
    public AssignMaintenanceValidator()
    {
        RuleFor(x => x.AssignedToUserId)
            .GreaterThan(0)
            .WithMessage("Valid user ID is required for assignment");
    }
}

/// <summary>
/// Validator for bulk completion requests
/// </summary>
public class BulkCompleteValidator : AbstractValidator<BulkCompleteRequest>
{
    public BulkCompleteValidator()
    {
        RuleFor(x => x.IssueIds)
            .NotNull()
            .WithMessage("Issue IDs list is required")
            .NotEmpty()
            .WithMessage("At least one issue ID is required")
            .Must(HaveValidIds)
            .WithMessage("All issue IDs must be greater than 0");

        RuleFor(x => x.ResolutionNotes)
            .MaximumLength(500)
            .WithMessage("Resolution notes cannot exceed 500 characters")
            .When(x => !string.IsNullOrEmpty(x.ResolutionNotes));
    }

    private static bool HaveValidIds(List<int> issueIds)
    {
        return issueIds.All(id => id > 0);
    }
} 