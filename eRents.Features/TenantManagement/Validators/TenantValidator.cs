using eRents.Features.TenantManagement.DTOs;
using eRents.Features.Shared.Validation;
using FluentValidation;

namespace eRents.Features.TenantManagement.Validators;

/// <summary>
/// Validator for tenant creation requests using standardized base validation patterns
/// </summary>
public class TenantCreateValidator : BaseEntityValidator<TenantCreateRequest>
{
    private static readonly string[] ValidTenantStatuses = { "Active", "Completed", "Cancelled", "Pending" };

    public TenantCreateValidator()
    {
        // Use standardized ID validation helpers
        ValidateRequiredId(x => x.UserId, "User ID");
        ValidateRequiredId(x => x.PropertyId, "Property ID");
        ValidateRequiredId(x => x.RentalRequestId, "Rental Request ID");

        // Use standardized date validation helpers
        ValidateRequiredDate(x => x.LeaseStartDate, "Lease start date",
            DateTime.Today.AddDays(-30), DateTime.Today.AddYears(5));

        ValidateRequiredDate(x => x.LeaseEndDate, "Lease end date",
            DateTime.Today.AddDays(-30), DateTime.Today.AddYears(5));

        // Use standardized date range validation
        ValidateDateRange(x => x.LeaseStartDate, x => x.LeaseEndDate,
            "Lease start date", "Lease end date");

        // Use standardized allowed values validation
        ValidateAllowedValues(x => x.TenantStatus, ValidTenantStatuses, "Tenant status");

        // Business rule: Lease duration should be reasonable (at least 7 days, max 5 years)
        RuleFor(x => x)
            .Must(HaveReasonableLeaseDuration)
            .WithMessage("Lease duration must be between 7 days and 5 years");
    }

    private static bool HaveReasonableLeaseDuration(TenantCreateRequest request)
    {
        var duration = request.LeaseEndDate - request.LeaseStartDate;
        return duration.TotalDays >= 7 && duration.TotalDays <= (365 * 5); // 7 days to 5 years
    }
}

/// <summary>
/// Validator for tenant preference update requests using standardized base validation patterns
/// </summary>
public class TenantPreferenceValidator : BaseEntityValidator<TenantPreferenceUpdateRequest>
{
    public TenantPreferenceValidator()
    {
        // Use standardized date validation helpers
        ValidateRequiredDate(x => x.SearchStartDate, "Search start date",
            DateTime.Today.AddDays(-1), DateTime.Today.AddYears(2));

        // Use standardized optional date range validation for nullable dates
        ValidateOptionalDateRange(x => x.SearchStartDate, x => x.SearchEndDate,
            "Search start date", "Search end date");

        // Use standardized text validation helpers
        ValidateRequiredText(x => x.City, "City", maxLength: 100, minLength: 2);
        ValidateOptionalText(x => x.Description, "Description", maxLength: 1000);

        // Custom price validations (since BaseValidator doesn't have optional decimal validation)
        RuleFor(x => x.MinPrice)
            .GreaterThanOrEqualTo(0)
            .WithMessage("Minimum price must be non-negative")
            .When(x => x.MinPrice.HasValue);

        RuleFor(x => x.MaxPrice)
            .GreaterThanOrEqualTo(0)
            .WithMessage("Maximum price must be non-negative")
            .When(x => x.MaxPrice.HasValue);

        RuleFor(x => x.MaxPrice)
            .GreaterThanOrEqualTo(x => x.MinPrice)
            .WithMessage("Maximum price must be greater than or equal to minimum price")
            .When(x => x.MinPrice.HasValue && x.MaxPrice.HasValue);

        // Custom ID list validation
        RuleFor(x => x.AmenityIds)
            .Must(HaveValidAmenityIds)
            .WithMessage("All amenity IDs must be greater than 0")
            .When(x => x.AmenityIds != null && x.AmenityIds.Any());

        // Business rule: Search duration should be reasonable (max 2 years)
        RuleFor(x => x)
            .Must(HaveReasonableSearchDuration)
            .WithMessage("Search duration cannot exceed 2 years")
            .When(x => x.SearchEndDate.HasValue);

        // Business rule: Price range should be reasonable (max price shouldn't be more than 100x min price)
        RuleFor(x => x)
            .Must(HaveReasonablePriceRange)
            .WithMessage("Price range is unrealistic - maximum price is too high compared to minimum price")
            .When(x => x.MinPrice.HasValue && x.MaxPrice.HasValue && x.MinPrice > 0);
    }

    private static bool HaveValidAmenityIds(List<int> amenityIds)
    {
        return amenityIds.All(id => id > 0);
    }

    private static bool HaveReasonableSearchDuration(TenantPreferenceUpdateRequest request)
    {
        if (!request.SearchEndDate.HasValue) return true;
        var duration = request.SearchEndDate.Value - request.SearchStartDate;
        return duration.TotalDays <= (365 * 2); // Max 2 years
    }

    private static bool HaveReasonablePriceRange(TenantPreferenceUpdateRequest request)
    {
        if (!request.MinPrice.HasValue || !request.MaxPrice.HasValue || request.MinPrice.Value <= 0)
            return true;
        
        var ratio = request.MaxPrice.Value / request.MinPrice.Value;
        return ratio <= 100; // Max price shouldn't be more than 100x min price
    }
}

/// <summary>
/// Validator for tenant search objects using standardized base validation patterns
/// </summary>
public class TenantSearchValidator : BaseEntityValidator<TenantSearchObject>
{
    private static readonly string[] ValidSortFields =
    {
        "TenantId", "UserId", "PropertyId", "LeaseStartDate", "LeaseEndDate",
        "TenantStatus", "CreatedAt", "UpdatedAt"
    };
    
    private static readonly string[] ValidTenantStatuses = { "Active", "Completed", "Cancelled", "Pending" };

    public TenantSearchValidator()
    {
        // Use standardized pagination validation
        ValidateRequiredPositiveInt(x => x.Page, "Page number", minValue: 1);
        ValidateRequiredPositiveInt(x => x.PageSize, "Page size", minValue: 1, maxValue: 100);

        // Use standardized allowed values validation for optional fields
        RuleFor(x => x.SortBy)
            .Must(BeValidSortField)
            .WithMessage($"Sort field must be one of: {string.Join(", ", ValidSortFields)}")
            .When(x => !string.IsNullOrEmpty(x.SortBy));

        // Optional ID validations using custom rules (since BaseValidator doesn't have optional ID validation)
        RuleFor(x => x.UserId)
            .GreaterThan(0)
            .WithMessage("Valid user ID is required")
            .When(x => x.UserId.HasValue);

        RuleFor(x => x.PropertyId)
            .GreaterThan(0)
            .WithMessage("Valid property ID is required")
            .When(x => x.PropertyId.HasValue);

        // Use standardized text validation for optional fields
        ValidateOptionalText(x => x.TenantStatus, "Tenant status", maxLength: 50);
        ValidateOptionalText(x => x.City, "City", maxLength: 100);

        // Custom validation for tenant status values
        RuleFor(x => x.TenantStatus)
            .Must(BeValidTenantStatus)
            .WithMessage($"Tenant status must be one of: {string.Join(", ", ValidTenantStatuses)}")
            .When(x => !string.IsNullOrEmpty(x.TenantStatus));

        // Use standardized optional date range validation
        ValidateOptionalDateRange(x => x.LeaseStartAfter, x => x.LeaseStartBefore,
            "Lease start after", "Lease start before");
        
        ValidateOptionalDateRange(x => x.LeaseEndAfter, x => x.LeaseEndBefore,
            "Lease end after", "Lease end before");

        // Custom price validations (optional decimal values)
        RuleFor(x => x.MinPrice)
            .GreaterThanOrEqualTo(0)
            .WithMessage("Minimum price must be non-negative")
            .When(x => x.MinPrice.HasValue);

        RuleFor(x => x.MaxPrice)
            .GreaterThanOrEqualTo(0)
            .WithMessage("Maximum price must be non-negative")
            .When(x => x.MaxPrice.HasValue);

        RuleFor(x => x.MaxPrice)
            .GreaterThanOrEqualTo(x => x.MinPrice)
            .WithMessage("Maximum price must be greater than or equal to minimum price")
            .When(x => x.MinPrice.HasValue && x.MaxPrice.HasValue);

        // Custom ID list validation
        RuleFor(x => x.AmenityIds)
            .Must(HaveValidAmenityIds)
            .WithMessage("All amenity IDs must be greater than 0")
            .When(x => x.AmenityIds != null && x.AmenityIds.Any());
    }

    private static bool BeValidSortField(string sortField)
    {
        return ValidSortFields.Contains(sortField, StringComparer.OrdinalIgnoreCase);
    }

    private static bool BeValidTenantStatus(string status)
    {
        return ValidTenantStatuses.Contains(status, StringComparer.OrdinalIgnoreCase);
    }

    private static bool HaveValidAmenityIds(List<int> amenityIds)
    {
        return amenityIds.All(id => id > 0);
    }
}