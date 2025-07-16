using eRents.Features.TenantManagement.DTOs;
using FluentValidation;

namespace eRents.Features.TenantManagement.Validators;

/// <summary>
/// Validator for tenant creation requests
/// </summary>
public class TenantCreateValidator : AbstractValidator<TenantCreateRequest>
{
    private static readonly string[] ValidTenantStatuses = { "Active", "Completed", "Cancelled", "Pending" };

    public TenantCreateValidator()
    {
        RuleFor(x => x.UserId)
            .GreaterThan(0)
            .WithMessage("Valid user ID is required");

        RuleFor(x => x.PropertyId)
            .GreaterThan(0)
            .WithMessage("Valid property ID is required");

        RuleFor(x => x.RentalRequestId)
            .GreaterThan(0)
            .WithMessage("Valid rental request ID is required");

        RuleFor(x => x.LeaseStartDate)
            .NotEmpty()
            .WithMessage("Lease start date is required")
            .GreaterThanOrEqualTo(DateTime.Today.AddDays(-30))
            .WithMessage("Lease start date cannot be more than 30 days in the past");

        RuleFor(x => x.LeaseEndDate)
            .NotEmpty()
            .WithMessage("Lease end date is required")
            .GreaterThan(x => x.LeaseStartDate)
            .WithMessage("Lease end date must be after lease start date");

        RuleFor(x => x.TenantStatus)
            .NotEmpty()
            .WithMessage("Tenant status is required")
            .Must(BeValidTenantStatus)
            .WithMessage($"Tenant status must be one of: {string.Join(", ", ValidTenantStatuses)}");

        // Business rule: Lease duration should be reasonable (at least 7 days, max 5 years)
        RuleFor(x => x)
            .Must(HaveReasonableLeaseDuration)
            .WithMessage("Lease duration must be between 7 days and 5 years");
    }

    private static bool BeValidTenantStatus(string status)
    {
        return ValidTenantStatuses.Contains(status, StringComparer.OrdinalIgnoreCase);
    }

    private static bool HaveReasonableLeaseDuration(TenantCreateRequest request)
    {
        var duration = request.LeaseEndDate - request.LeaseStartDate;
        return duration.TotalDays >= 7 && duration.TotalDays <= (365 * 5); // 7 days to 5 years
    }
}

/// <summary>
/// Validator for tenant preference update requests
/// </summary>
public class TenantPreferenceValidator : AbstractValidator<TenantPreferenceUpdateRequest>
{
    public TenantPreferenceValidator()
    {
        RuleFor(x => x.SearchStartDate)
            .NotEmpty()
            .WithMessage("Search start date is required")
            .GreaterThanOrEqualTo(DateTime.Today.AddDays(-1))
            .WithMessage("Search start date cannot be in the past");

        RuleFor(x => x.SearchEndDate)
            .GreaterThan(x => x.SearchStartDate)
            .WithMessage("Search end date must be after search start date")
            .When(x => x.SearchEndDate.HasValue);

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

        RuleFor(x => x.City)
            .NotEmpty()
            .WithMessage("City is required")
            .MaximumLength(100)
            .WithMessage("City name cannot exceed 100 characters")
            .MinimumLength(2)
            .WithMessage("City name must be at least 2 characters");

        RuleFor(x => x.AmenityIds)
            .Must(HaveValidAmenityIds)
            .WithMessage("All amenity IDs must be greater than 0")
            .When(x => x.AmenityIds != null && x.AmenityIds.Any());

        RuleFor(x => x.Description)
            .MaximumLength(1000)
            .WithMessage("Description cannot exceed 1000 characters");

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
/// Validator for tenant search objects
/// </summary>
public class TenantSearchValidator : AbstractValidator<TenantSearchObject>
{
    private static readonly string[] ValidSortFields = 
    { 
        "TenantId", "UserId", "PropertyId", "LeaseStartDate", "LeaseEndDate", 
        "TenantStatus", "CreatedAt", "UpdatedAt" 
    };
    
    private static readonly string[] ValidTenantStatuses = { "Active", "Completed", "Cancelled", "Pending" };

    public TenantSearchValidator()
    {
        RuleFor(x => x.Page)
            .GreaterThan(0)
            .WithMessage("Page number must be greater than 0");

        RuleFor(x => x.PageSize)
            .InclusiveBetween(1, 100)
            .WithMessage("Page size must be between 1 and 100");

        RuleFor(x => x.SortBy)
            .Must(BeValidSortField)
            .WithMessage($"Sort field must be one of: {string.Join(", ", ValidSortFields)}")
            .When(x => !string.IsNullOrEmpty(x.SortBy));

        RuleFor(x => x.UserId)
            .GreaterThan(0)
            .WithMessage("Valid user ID is required")
            .When(x => x.UserId.HasValue);

        RuleFor(x => x.PropertyId)
            .GreaterThan(0)
            .WithMessage("Valid property ID is required")
            .When(x => x.PropertyId.HasValue);

        RuleFor(x => x.TenantStatus)
            .Must(BeValidTenantStatus)
            .WithMessage($"Tenant status must be one of: {string.Join(", ", ValidTenantStatuses)}")
            .When(x => !string.IsNullOrEmpty(x.TenantStatus));

        RuleFor(x => x.LeaseStartAfter)
            .LessThanOrEqualTo(x => x.LeaseStartBefore)
            .WithMessage("Lease start 'after' date must be before or equal to 'before' date")
            .When(x => x.LeaseStartAfter.HasValue && x.LeaseStartBefore.HasValue);

        RuleFor(x => x.LeaseEndAfter)
            .LessThanOrEqualTo(x => x.LeaseEndBefore)
            .WithMessage("Lease end 'after' date must be before or equal to 'before' date")
            .When(x => x.LeaseEndAfter.HasValue && x.LeaseEndBefore.HasValue);

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

        RuleFor(x => x.City)
            .MaximumLength(100)
            .WithMessage("City name cannot exceed 100 characters")
            .When(x => !string.IsNullOrEmpty(x.City));

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