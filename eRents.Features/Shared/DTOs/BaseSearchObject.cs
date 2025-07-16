using System.ComponentModel.DataAnnotations;

namespace eRents.Features.Shared.DTOs;

/// <summary>
/// Base search object for all Features with pagination, sorting, and validation
/// Enhanced version moved from eRents.Shared for modular architecture
/// </summary>
public abstract class BaseSearchObject
{
	#region Pagination

	[Range(1, int.MaxValue, ErrorMessage = "Page must be greater than 0")]
	public int Page { get; set; } = 1;

	[Range(1, 100, ErrorMessage = "Page size must be between 1 and 100")]
	public int PageSize { get; set; } = 10;

	/// <summary>
	/// When true, returns all results without pagination
	/// </summary>
	public bool NoPaging { get; set; } = false;

	#endregion

	#region Search and Filtering

	[StringLength(500, ErrorMessage = "Search term cannot exceed 500 characters")]
	public string? SearchTerm { get; set; }

	/// <summary>
	/// Date range filtering (common across entities)
	/// </summary>
	public DateTime? DateFrom { get; set; }
	public DateTime? DateTo { get; set; }

	#endregion

	#region Sorting

	[StringLength(50, ErrorMessage = "Sort field name cannot exceed 50 characters")]
	public string? SortBy { get; set; }

	public bool SortDescending { get; set; } = false;

	#endregion

	#region Helper Properties

	public int PageNumber => Page;
	public int PageSizeValue => NoPaging ? int.MaxValue : Math.Min(PageSize, 100);

	/// <summary>
	/// Validation helper for date ranges
	/// </summary>
	public bool IsValidDateRange => !DateFrom.HasValue || !DateTo.HasValue || DateFrom <= DateTo;

	#endregion

	#region Validation Methods

	/// <summary>
	/// Gets all validation errors for this search object
	/// Override in derived classes to add specific validation
	/// </summary>
	public virtual List<string> GetValidationErrors()
	{
		var errors = new List<string>();

		if (!IsValidDateRange)
			errors.Add("DateFrom must be before or equal to DateTo");

		return errors;
	}

	/// <summary>
	/// Checks if the search object is valid
	/// </summary>
	public bool IsValid => GetValidationErrors().Count == 0;

	#endregion
}