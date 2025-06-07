using System;
using System.ComponentModel.DataAnnotations;

namespace eRents.Shared.SearchObjects
{
	public class BaseSearchObject
	{
		// Pagination
		[Range(1, int.MaxValue, ErrorMessage = "Page must be greater than 0")]
		public int? Page { get; set; } = 1;
		
		[Range(1, 100, ErrorMessage = "Page size must be between 1 and 100")]
		public int? PageSize { get; set; } = 10;
		
		// NEW: No Paging option - when true, returns all results without pagination
		public bool NoPaging { get; set; } = false;
		
		// NEW: Search functionality
		[StringLength(500, ErrorMessage = "Search term cannot exceed 500 characters")]
		public string? SearchTerm { get; set; }
		
		// NEW: Sorting functionality
		[StringLength(50, ErrorMessage = "Sort field name cannot exceed 50 characters")]
		public string? SortBy { get; set; }
		
		public bool SortDescending { get; set; } = false;
		
		// NEW: Date range filtering (common across entities)
		public DateTime? DateFrom { get; set; }
		public DateTime? DateTo { get; set; }
		
		// Helper properties
		public int PageNumber => Page ?? 1;
		public int PageSizeValue => NoPaging ? int.MaxValue : Math.Min(PageSize ?? 10, 100); // Max 100 items per page unless NoPaging
		
		// Validation helper
		public bool IsValidDateRange => !DateFrom.HasValue || !DateTo.HasValue || DateFrom <= DateTo;
	}
}
