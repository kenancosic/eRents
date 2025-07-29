using eRents.Features.Shared.Validation;
using eRents.Features.RentalManagement.DTOs;
using FluentValidation;
using eRents.Domain.Models.Enums;

namespace eRents.Features.RentalManagement.Validators;

/// <summary>
/// Validator for rental request creation/updates
/// </summary>
public class RentalRequestValidator : BaseEntityValidator<RentalRequestRequest>
{
	public RentalRequestValidator()
	{
		ValidateRequiredId(x => x.PropertyId, "Property ID");
		
		RuleFor(x => x.StartDate)
			.NotEmpty()
			.WithMessage("Start date is required");
			
		RuleFor(x => x.EndDate)
			.NotEmpty()
			.WithMessage("End date is required");
			
		RuleFor(x => x.NumberOfGuests)
			.GreaterThan(0)
			.WithMessage("Number of guests must be greater than 0")
			.LessThanOrEqualTo(20)
			.WithMessage("Number of guests cannot exceed 20");
			
		RuleFor(x => x.TotalPrice)
			.GreaterThanOrEqualTo(0)
			.WithMessage("Total price must be non-negative");
		
		RuleFor(x => x.Currency)
				.Must(BeValidCurrency)
				.WithMessage($"Currency must be one of: BAM, EUR, USD");

		RuleFor(x => x.RentalType)
				.IsInEnum()
				.WithMessage("Rental type must be a valid enum value");

		ValidateOptionalText(x => x.SpecialRequests, "Special requests", 500);

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
		return new[] { "BAM", "EUR", "USD" }.Contains(currency, StringComparer.OrdinalIgnoreCase);
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
public class RentalApprovalValidator : BaseEntityValidator<RentalApprovalRequest>
{
	public RentalApprovalValidator()
	{
		ValidateOptionalText(x => x.Reason, "Reason", 1000);
		ValidateOptionalText(x => x.Notes, "Notes", 2000);
	}
}

// StartCoordinationValidator removed - coordination functionality was simplified

/// <summary>
/// Validator for creating tenant from rental request
/// </summary>
public class CreateTenantFromRentalValidator : BaseEntityValidator<CreateTenantFromRentalRequest>
{
	public CreateTenantFromRentalValidator()
	{
		ValidateRequiredId(x => x.RentalRequestId, "Rental request ID");
		ValidateRequiredId(x => x.UserId, "User ID");
		ValidateRequiredId(x => x.PropertyId, "Property ID");
		
		RuleFor(x => x.StartDate)
			.NotEmpty()
			.WithMessage("Start date is required");
			
		RuleFor(x => x.EndDate)
			.NotEmpty()
			.WithMessage("End date is required");
			
		RuleFor(x => x.MonthlyRent)
			.GreaterThanOrEqualTo(0.01m)
			.WithMessage("Monthly rent must be at least 0.01")
			.LessThanOrEqualTo(50000)
			.WithMessage("Monthly rent cannot exceed 50,000");
			
		RuleFor(x => x.SecurityDeposit)
			.GreaterThanOrEqualTo(0)
			.WithMessage("Security deposit must be non-negative")
			.LessThanOrEqualTo(100000)
			.WithMessage("Security deposit cannot exceed 100,000");
			
		RuleFor(x => x.SpecialTerms)
			.MaximumLength(1000)
			.WithMessage("Special terms cannot exceed 1000 characters")
			.When(x => !string.IsNullOrEmpty(x.SpecialTerms));
			
		RuleFor(x => x.Notes)
			.MaximumLength(1000)
			.WithMessage("Notes cannot exceed 1000 characters")
			.When(x => !string.IsNullOrEmpty(x.Notes));

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
public class RentalFilterValidator : BaseEntityValidator<RentalFilterRequest>
{
	public RentalFilterValidator()
	{
		RuleFor(x => x.PropertyId)
			.GreaterThan(0)
			.WithMessage("Property ID must be greater than 0")
			.When(x => x.PropertyId.HasValue);
			
		RuleFor(x => x.UserId)
			.GreaterThan(0)
			.WithMessage("User ID must be greater than 0")
			.When(x => x.UserId.HasValue);
			
		RuleFor(x => x.LandlordId)
			.GreaterThan(0)
			.WithMessage("Landlord ID must be greater than 0")
			.When(x => x.LandlordId.HasValue);
			
		RuleFor(x => x.Status)
			.MaximumLength(50)
			.WithMessage("Status cannot exceed 50 characters")
			.When(x => !string.IsNullOrEmpty(x.Status));
			
		RuleFor(x => x.SortBy)
			.MaximumLength(50)
			.WithMessage("Sort field cannot exceed 50 characters")
			.When(x => !string.IsNullOrEmpty(x.SortBy));
			
		RuleFor(x => x.SortOrder)
			.MaximumLength(4)
			.WithMessage("Sort order cannot exceed 4 characters")
			.When(x => !string.IsNullOrEmpty(x.SortOrder));
			
		RuleFor(x => x.Page)
			.GreaterThan(0)
			.WithMessage("Page number must be greater than 0");
			
		RuleFor(x => x.PageSize)
			.GreaterThan(0)
			.WithMessage("Page size must be greater than 0")
			.LessThanOrEqualTo(100)
			.WithMessage("Page size cannot exceed 100");
			
		RuleFor(x => x.MinPrice)
			.GreaterThanOrEqualTo(0)
			.WithMessage("Minimum price must be non-negative")
			.When(x => x.MinPrice.HasValue);
			
		RuleFor(x => x.MaxPrice)
			.GreaterThanOrEqualTo(0)
			.WithMessage("Maximum price must be non-negative")
			.When(x => x.MaxPrice.HasValue);
		
		RuleFor(x => x.StartDate)
				.LessThanOrEqualTo(x => x.EndDate)
				.WithMessage("Start date must be before or equal to end date")
				.When(x => x.StartDate.HasValue && x.EndDate.HasValue);

		RuleFor(x => x.MaxPrice)
				.GreaterThanOrEqualTo(x => x.MinPrice)
				.WithMessage("Maximum price must be greater than or equal to minimum price")
				.When(x => x.MinPrice.HasValue && x.MaxPrice.HasValue);

		RuleFor(x => x.SearchTerm)
				.MaximumLength(100)
				.WithMessage("Search term cannot exceed 100 characters");
	}
}

// Note: BulkRentalActionValidator removed as bulk operations were eliminated during debloating 