using eRents.Features.RentalManagement.DTOs;
using FluentValidation;
using eRents.Domain.Models.Enums;

namespace eRents.Features.RentalManagement.Validators;

/// <summary>
/// Validator for rental request creation/updates
/// </summary>
public class RentalRequestValidator : AbstractValidator<RentalRequestRequest>
{
	private static readonly string[] ValidCurrencies = { "BAM", "EUR", "USD" };
	private static readonly string[] ValidRentalTypes = { "Daily", "Monthly", "Annual" };

	public RentalRequestValidator()
	{
		RuleFor(x => x.PropertyId)
				.GreaterThan(0)
				.WithMessage("Valid property ID is required");

		// BookingId is not part of RentalRequestRequest

		RuleFor(x => x.StartDate)
				.NotEmpty()
				.WithMessage("Start date is required")
				.GreaterThanOrEqualTo(DateTime.Today)
				.WithMessage("Start date cannot be in the past");

		RuleFor(x => x.EndDate)
				.NotEmpty()
				.WithMessage("End date is required")
				.GreaterThan(x => x.StartDate)
				.WithMessage("End date must be after start date");

		RuleFor(x => x.NumberOfGuests)
				.InclusiveBetween(1, 20)
				.WithMessage("Number of guests must be between 1 and 20");

		RuleFor(x => x.TotalPrice)
				.GreaterThanOrEqualTo(0)
				.WithMessage("Total price must be non-negative")
				.LessThanOrEqualTo(100000)
				.WithMessage("Total price cannot exceed 100,000");

		RuleFor(x => x.Currency)
				.NotEmpty()
				.WithMessage("Currency is required")
				.Must(BeValidCurrency)
				.WithMessage($"Currency must be one of: {string.Join(", ", ValidCurrencies)}");

		RuleFor(x => x.RentalType)
				.IsInEnum()
				.WithMessage("Rental type must be a valid enum value");

		RuleFor(x => x.SpecialRequests)
				.MaximumLength(500)
				.WithMessage("Special requests cannot exceed 500 characters");

		// Business rule: Rental duration should match rental type
		RuleFor(x => x)
				.Must(HaveConsistentRentalDuration)
				.WithMessage("Rental duration must be appropriate for the selected rental type");

		// Business rule: Reasonable duration limits
		RuleFor(x => x)
				.Must(HaveReasonableDuration)
				.WithMessage("Rental duration must be reasonable (1 day to 5 years)");
	}

	private static bool BeValidCurrency(string currency)
	{
		return ValidCurrencies.Contains(currency, StringComparer.OrdinalIgnoreCase);
	}

	private static bool HaveConsistentRentalDuration(RentalRequestRequest request)
	{
		var duration = (request.EndDate - request.StartDate).Days;

		return request.RentalType switch
		{
			RentalType.Daily => duration >= 1 && duration <= 30,      // 1-30 days for daily rentals
			RentalType.Monthly => duration >= 28 && duration <= 366,  // 28 days to 1 year for monthly
			_ => true
		};
	}

	private static bool HaveReasonableDuration(RentalRequestRequest request)
	{
		var duration = (request.EndDate - request.StartDate).Days;
		return duration >= 1 && duration <= (365 * 5); // 1 day to 5 years
	}
}

/// <summary>
/// Validator for rental approval requests
/// </summary>
public class RentalApprovalValidator : AbstractValidator<RentalApprovalRequest>
{
	public RentalApprovalValidator()
	{
		RuleFor(x => x.Reason)
				.MaximumLength(1000)
				.WithMessage("Reason cannot exceed 1000 characters");

		RuleFor(x => x.Notes)
				.MaximumLength(2000)
				.WithMessage("Notes cannot exceed 2000 characters");
	}

	// Helper method removed - no longer needed with simplified approval request
}

// StartCoordinationValidator removed - coordination functionality was simplified

/// <summary>
/// Validator for creating tenant from rental request
/// </summary>
public class CreateTenantFromRentalValidator : AbstractValidator<CreateTenantFromRentalRequest>
{
	private static readonly string[] ValidCurrencies = { "BAM", "EUR", "USD" };

	public CreateTenantFromRentalValidator()
	{
		RuleFor(x => x.RentalRequestId)
				.GreaterThan(0)
				.WithMessage("Valid rental request ID is required");

		RuleFor(x => x.UserId)
				.GreaterThan(0)
				.WithMessage("Valid user ID is required");

		RuleFor(x => x.PropertyId)
				.GreaterThan(0)
				.WithMessage("Valid property ID is required");

		RuleFor(x => x.StartDate)
				.NotEmpty()
				.WithMessage("Start date is required")
				.GreaterThanOrEqualTo(DateTime.Today.AddDays(-7))
				.WithMessage("Start date cannot be more than 7 days in the past");

		RuleFor(x => x.EndDate)
				.NotEmpty()
				.WithMessage("End date is required")
				.GreaterThan(x => x.StartDate)
				.WithMessage("End date must be after start date");

		RuleFor(x => x.MonthlyRent)
				.GreaterThan(0)
				.WithMessage("Monthly rent must be greater than 0")
				.LessThanOrEqualTo(50000)
				.WithMessage("Monthly rent cannot exceed 50,000");

		RuleFor(x => x.SecurityDeposit)
				.GreaterThanOrEqualTo(0)
				.WithMessage("Security deposit must be non-negative")
				.LessThanOrEqualTo(100000)
				.WithMessage("Security deposit cannot exceed 100,000");

		RuleFor(x => x.SpecialTerms)
				.MaximumLength(1000)
				.WithMessage("Special terms cannot exceed 1000 characters");

		RuleFor(x => x.Notes)
				.MaximumLength(1000)
				.WithMessage("Notes cannot exceed 1000 characters");

		// Business rule: Lease duration should be reasonable
		RuleFor(x => x)
				.Must(HaveReasonableLeaseDuration)
				.WithMessage("Lease duration must be between 7 days and 5 years");

		// Business rule: Security deposit should be reasonable compared to monthly rent
		RuleFor(x => x)
				.Must(HaveReasonableSecurityDeposit)
				.WithMessage("Security deposit should not exceed 6 months of rent")
				.When(x => x.MonthlyRent > 0);
	}

	private static bool BeValidCurrency(string currency)
	{
		return ValidCurrencies.Contains(currency, StringComparer.OrdinalIgnoreCase);
	}

	private static bool HaveReasonableLeaseDuration(CreateTenantFromRentalRequest request)
	{
		var duration = (request.EndDate - request.StartDate).Days;
		return duration >= 7 && duration <= (365 * 5); // 7 days to 5 years
	}

	private static bool HaveReasonableSecurityDeposit(CreateTenantFromRentalRequest request)
	{
		if (request.MonthlyRent <= 0) return true;
		return request.SecurityDeposit <= (request.MonthlyRent * 6); // Max 6 months rent
	}
}

/// <summary>
/// Validator for rental filter requests
/// </summary>
public class RentalFilterValidator : AbstractValidator<RentalFilterRequest>
{
	private static readonly string[] ValidStatuses = { "Pending", "Approved", "Rejected", "Cancelled" };
	private static readonly string[] ValidRentalTypes = { "Daily", "Monthly", "Annual" };
	private static readonly string[] ValidSortFields = { "CreatedAt", "StartDate", "TotalPrice", "Status", "EndDate" };
	private static readonly string[] ValidSortOrders = { "ASC", "DESC" };

	public RentalFilterValidator()
	{
		RuleFor(x => x.PropertyId)
				.GreaterThan(0)
				.WithMessage("Valid property ID is required")
				.When(x => x.PropertyId.HasValue);

		RuleFor(x => x.UserId)
				.GreaterThan(0)
				.WithMessage("Valid user ID is required")
				.When(x => x.UserId.HasValue);

		RuleFor(x => x.LandlordId)
				.GreaterThan(0)
				.WithMessage("Valid landlord ID is required")
				.When(x => x.LandlordId.HasValue);

		RuleFor(x => x.Status)
				.Must(BeValidStatus)
				.WithMessage($"Status must be one of: {string.Join(", ", ValidStatuses)}")
				.When(x => !string.IsNullOrEmpty(x.Status));

		RuleFor(x => x.RentalType)
				.IsInEnum()
				.WithMessage("Rental type must be a valid enum value")
				.When(x => x.RentalType.HasValue);

		RuleFor(x => x.StartDate)
				.LessThanOrEqualTo(x => x.EndDate)
				.WithMessage("Start date must be before or equal to end date")
				.When(x => x.StartDate.HasValue && x.EndDate.HasValue);

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

		RuleFor(x => x.SearchTerm)
				.MaximumLength(100)
				.WithMessage("Search term cannot exceed 100 characters");

		RuleFor(x => x.SortBy)
				.Must(BeValidSortField)
				.WithMessage($"Sort field must be one of: {string.Join(", ", ValidSortFields)}")
				.When(x => !string.IsNullOrEmpty(x.SortBy));

		RuleFor(x => x.SortOrder)
				.Must(BeValidSortOrder)
				.WithMessage($"Sort order must be one of: {string.Join(", ", ValidSortOrders)}")
				.When(x => !string.IsNullOrEmpty(x.SortOrder));

		RuleFor(x => x.PageNumber)
				.GreaterThan(0)
				.WithMessage("Page number must be greater than 0")
				.When(x => x.PageNumber.HasValue);

		RuleFor(x => x.PageSize)
				.InclusiveBetween(1, 100)
				.WithMessage("Page size must be between 1 and 100")
				.When(x => x.PageSize.HasValue);
	}

	private static bool BeValidStatus(string status)
	{
		return ValidStatuses.Contains(status, StringComparer.OrdinalIgnoreCase);
	}

	// BeValidRentalType method removed - using IsInEnum instead

	private static bool BeValidSortField(string sortField)
	{
		return ValidSortFields.Contains(sortField, StringComparer.OrdinalIgnoreCase);
	}

	private static bool BeValidSortOrder(string sortOrder)
	{
		return ValidSortOrders.Contains(sortOrder, StringComparer.OrdinalIgnoreCase);
	}
}

// Note: BulkRentalActionValidator removed as bulk operations were eliminated during debloating 