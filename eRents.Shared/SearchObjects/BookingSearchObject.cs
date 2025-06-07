using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace eRents.Shared.SearchObjects
{
	/// <summary>
	/// Search object for Booking entities with enhanced filtering and sorting capabilities.
	/// 
	/// SearchTerm searches across: Property Name, Tenant Name (FirstName + LastName), Booking ID
	/// SortBy supports: "Date", "Property", "Status", "Amount", "Guest", "Created"
	/// DateFrom/DateTo filters by booking creation date (CreatedAt)
	/// </summary>
	public class BookingSearchObject : BaseSearchObject
	{
		// ✅ ALIGNED: Match Booking entity property names exactly
		public int? PropertyId { get; set; }
		public int? UserId { get; set; }
		
		[Display(Name = "Booking Start Date")]
		public DateTime? StartDate { get; set; }
		
		[Display(Name = "Booking End Date")]
		public DateTime? EndDate { get; set; }
		
		// ✅ ALIGNED: Use entity property name for exact match filtering
		public int? BookingStatusId { get; set; }
		
		// ✅ ALIGNED: Range filtering for TotalPrice property
		[Range(0, double.MaxValue, ErrorMessage = "Minimum amount must be positive")]
		public decimal? MinTotalPrice { get; set; }
		
		[Range(0, double.MaxValue, ErrorMessage = "Maximum amount must be positive")]
		public decimal? MaxTotalPrice { get; set; }
		
		// ✅ ALIGNED: Match entity property names for exact filtering
		public string? PaymentMethod { get; set; }
		public string? Currency { get; set; }
		public string? PaymentStatus { get; set; }
		public int? MinNumberOfGuests { get; set; }
		public int? MaxNumberOfGuests { get; set; }
		
		// ✅ HELPER: Navigation property helpers (for UI convenience)
		// These don't match entity properties but provide easy filtering
		[StringLength(50, ErrorMessage = "Status cannot exceed 50 characters")]
		public string? Status { get; set; } // Maps to BookingStatus.StatusName
		
		/// <summary>
		/// Multiple status filtering (e.g., ["Confirmed", "Pending"]) 
		/// Maps to BookingStatus.StatusName
		/// </summary>
		public List<string>? Statuses { get; set; }
		
		// Helper methods for validation  
		public bool IsValidAmountRange => !MinTotalPrice.HasValue || !MaxTotalPrice.HasValue || MinTotalPrice <= MaxTotalPrice;
		public bool IsValidGuestRange => !MinNumberOfGuests.HasValue || !MaxNumberOfGuests.HasValue || MinNumberOfGuests <= MaxNumberOfGuests;
		public bool IsValidBookingDateRange => !StartDate.HasValue || !EndDate.HasValue || StartDate <= EndDate;
		
		/// <summary>
		/// Gets all validation errors for this search object
		/// </summary>
		public List<string> GetValidationErrors()
		{
			var errors = new List<string>();
			
			if (!IsValidDateRange)
				errors.Add("DateFrom must be before or equal to DateTo");
				
			if (!IsValidAmountRange)
				errors.Add("MinTotalPrice must be less than or equal to MaxTotalPrice");
				
			if (!IsValidGuestRange)
				errors.Add("MinNumberOfGuests must be less than or equal to MaxNumberOfGuests");
				
			if (!IsValidBookingDateRange)
				errors.Add("StartDate must be before or equal to EndDate");
				
			return errors;
		}
	}
}
