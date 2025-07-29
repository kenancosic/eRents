using eRents.Features.MaintenanceManagement.DTOs;
using eRents.Features.Shared.Validation;
using FluentValidation;

namespace eRents.Features.MaintenanceManagement.Validators;

/// <summary>
/// Comprehensive validator for maintenance issue requests
/// Handles validation for creating and updating reactive maintenance issues
/// </summary>
public class MaintenanceIssueValidator : BaseEntityValidator<MaintenanceIssueRequest>
{
    private static readonly string[] ValidPriorities = { "Low", "Medium", "High", "Emergency" };

    public MaintenanceIssueValidator()
    {
        ValidateRequiredId(x => x.PropertyId, "Property ID");

        RuleFor(x => x.AssignedToUserId)
            .GreaterThan(0)
            .WithMessage("Valid assigned user ID is required")
            .When(x => x.AssignedToUserId.HasValue);

        ValidateRequiredText(x => x.Title, "Title", 200);

        ValidateOptionalText(x => x.Description, "Description", 1000);

        RuleFor(x => x.Priority)
            .NotEmpty()
            .WithMessage("Priority is required")
            .Must(BeValidPriority)
            .WithMessage($"Priority must be one of: {string.Join(", ", ValidPriorities)}");

        RuleFor(x => x.Cost)
            .GreaterThanOrEqualTo(0)
            .WithMessage("Cost must be non-negative")
            .When(x => x.Cost.HasValue);

        ValidateOptionalText(x => x.Category, "Category", 100);

        ValidateOptionalText(x => x.ResolutionNotes, "Resolution notes", 500);
    }

    private static bool BeValidPriority(string priority)
    {
        return ValidPriorities.Contains(priority, StringComparer.OrdinalIgnoreCase);
    }
}

/// <summary>
/// Validator for maintenance status update requests
/// </summary>
public class MaintenanceStatusUpdateValidator : BaseEntityValidator<MaintenanceStatusUpdateRequest>
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

        ValidateOptionalText(x => x.ResolutionNotes, "Resolution notes", 500);

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
public class AssignMaintenanceValidator : BaseEntityValidator<AssignMaintenanceRequest>
{
    public AssignMaintenanceValidator()
    {
        ValidateRequiredId(x => x.AssignedToUserId, "User ID for assignment");
    }
}

/// <summary>
/// Validator for bulk completion requests
/// </summary>
public class BulkCompleteValidator : BaseEntityValidator<BulkCompleteRequest>
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

        ValidateOptionalText(x => x.ResolutionNotes, "Resolution notes", 500);
    }

    private static bool HaveValidIds(List<int> issueIds)
    {
        return issueIds.All(id => id > 0);
    }
}