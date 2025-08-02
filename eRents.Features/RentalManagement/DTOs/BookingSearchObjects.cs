using System.ComponentModel.DataAnnotations;
using eRents.Domain.Models.Enums;
using eRents.Features.Shared.DTOs;

namespace eRents.Features.RentalManagement.DTOs;

/// <summary>
/// Basic booking search with essential filters for common use cases
/// Simplified interface for general booking searching
/// Consolidated from BookingManagement module
/// </summary>
public class BasicBookingSearch : BasicSearchObject
{
	#region Core Booking Filters

	/// <summary>
	/// Filter by property ID
	/// </summary>
	public int? PropertyId { get; set; }

	/// <summary>
	/// Filter by user ID
	/// </summary>
	public int? UserId { get; set; }

	/// <summary>
	/// Filter by booking status name
	/// </summary>
	[StringLength(50, ErrorMessage = "Booking Status Name cannot exceed 50 characters")]
	public string? BookingStatusName { get; set; }

	/// <summary>
	/// Minimum total price filter
	/// </summary>
	[Range(0.01, 999999.99, ErrorMessage = "MinPrice must be between 0.01 and 999999.99")]
	public decimal? MinPrice { get; set; }

	/// <summary>
	/// Maximum total price filter
	/// </summary>
	[Range(0.01, 999999.99, ErrorMessage = "MaxPrice must be between 0.01 and 999999.99")]
	public decimal? MaxPrice { get; set; }

	/// <summary>
	/// Filter by start date (from)
	/// </summary>
	public DateTime? StartDateFrom { get; set; }

	/// <summary>
	/// Filter by start date (to)
	/// </summary>
	public DateTime? StartDateTo { get; set; }

	#endregion

	#region Validation Methods

	/// <summary>
	/// Basic booking search validation
	/// </summary>
	public override List<string> GetValidationErrors()
	{
		var errors = base.GetValidationErrors();

		if (!IsValidPriceRange)
			errors.Add("MinPrice must be less than or equal to MaxPrice");

		if (!IsValidStartDateRange)
			errors.Add("StartDateFrom must be before or equal to StartDateTo");

		return errors;
	}

	#endregion

	#region Helper Properties

	/// <summary>
	/// Validation helper for price range
	/// </summary>
	public bool IsValidPriceRange => !MinPrice.HasValue || !MaxPrice.HasValue || MinPrice <= MaxPrice;

	/// <summary>
	/// Validation helper for start date range
	/// </summary>
	public bool IsValidStartDateRange => !StartDateFrom.HasValue || !StartDateTo.HasValue || StartDateFrom <= StartDateTo;

	#endregion
}

/// <summary>
/// Advanced booking search with comprehensive filtering options
/// Extends BasicBookingSearch for power users who need complex filtering
/// </summary>
public class AdvancedBookingSearch : BasicBookingSearch
{
	#region Extended Booking Filters

	/// <summary>
	/// Filter by booking status enum
	/// </summary>
	public BookingStatusEnum? Status { get; set; }

	/// <summary>
	/// Filter by minimum number of guests
	/// </summary>
	[Range(1, 20, ErrorMessage = "MinGuests must be between 1 and 20")]
	public int? MinGuests { get; set; }

	/// <summary>
	/// Filter by maximum number of guests
	/// </summary>
	[Range(1, 20, ErrorMessage = "MaxGuests must be between 1 and 20")]
	public int? MaxGuests { get; set; }

	/// <summary>
	/// Filter by end date (from)
	/// </summary>
	public DateTime? EndDateFrom { get; set; }

	/// <summary>
	/// Filter by end date (to)
	/// </summary>
	public DateTime? EndDateTo { get; set; }

	/// <summary>
	/// Filter by payment status
	/// </summary>
	[StringLength(50, ErrorMessage = "Payment status cannot exceed 50 characters")]
	public string? PaymentStatus { get; set; }

	/// <summary>
	/// Filter by payment method
	/// </summary>
	[StringLength(50, ErrorMessage = "Payment method cannot exceed 50 characters")]
	public string? PaymentMethod { get; set; }

	/// <summary>
	/// Include cancelled bookings in results
	/// </summary>
	public bool IncludeCancelled { get; set; } = false;

	#endregion

	#region Validation Methods

	/// <summary>
	/// Advanced booking search validation with all range checks
	/// </summary>
	public override List<string> GetValidationErrors()
	{
		var errors = base.GetValidationErrors();

		if (!IsValidEndDateRange)
			errors.Add("EndDateFrom must be before or equal to EndDateTo");

		if (!IsValidGuestRange)
			errors.Add("MinGuests must be less than or equal to MaxGuests");

		return errors;
	}

	#endregion

	#region Helper Properties

	/// <summary>
	/// Indicates this is an advanced search
	/// </summary>
	public override bool IsBasicSearch => false;

	/// <summary>
	/// Validation helper for end date range
	/// </summary>
	public bool IsValidEndDateRange => !EndDateFrom.HasValue || !EndDateTo.HasValue || EndDateFrom <= EndDateTo;

	/// <summary>
	/// Validation helper for guest range
	/// </summary>
	public bool IsValidGuestRange => !MinGuests.HasValue || !MaxGuests.HasValue || MinGuests <= MaxGuests;

	#endregion
}

/// <summary>
/// Search object for booking queries with filtering and pagination
/// Now extends AdvancedBookingSearch to leverage the new simplified hierarchy
/// Maintains backward compatibility for existing API endpoints
/// </summary>
public class BookingSearchObject : AdvancedBookingSearch
{

	#region Factory Methods

	/// <summary>
	/// Create a basic booking search from this comprehensive search object
	/// </summary>
	/// <returns>BasicBookingSearch with core filters only</returns>
	public BasicBookingSearch ToBasicSearch()
	{
		return new BasicBookingSearch
		{
			// Map pagination
			Page = Page,
			PageSize = PageSize,
			NoPaging = NoPaging,

			// Map basic search
			SearchTerm = SearchTerm,
			SearchText = SearchText,
			BookingStatusName = BookingStatusName, // Use BookingStatusName for basic search

			// Map core booking filters
			PropertyId = PropertyId,
			UserId = UserId,
			MinPrice = MinPrice,
			MaxPrice = MaxPrice,
			StartDateFrom = StartDateFrom,
			StartDateTo = StartDateTo,

			// Map sorting
			SortBy = SortBy,
			SortDescending = SortDescending
		};
	}

	/// <summary>
	/// Create an advanced booking search from this comprehensive search object
	/// (essentially returns itself since BookingSearchObject extends AdvancedBookingSearch)
	/// </summary>
	/// <returns>This object as AdvancedBookingSearch</returns>
	public AdvancedBookingSearch ToAdvancedSearch()
	{
		return this;
	}

	/// <summary>
	/// Check if this search object uses only basic search features
	/// Used for UI logic and performance optimization
	/// </summary>
	/// <returns>True if only basic features are used</returns>
	public bool IsEffectivelyBasicSearch()
	{
		return !base.Status.HasValue &&
					 !MinGuests.HasValue &&
					 !MaxGuests.HasValue &&
					 !EndDateFrom.HasValue &&
					 !EndDateTo.HasValue &&
					 string.IsNullOrEmpty(PaymentStatus) &&
					 string.IsNullOrEmpty(PaymentMethod) &&
					 !IncludeCancelled;
	}

	#endregion
}