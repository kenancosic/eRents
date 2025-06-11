using System;
using eRents.Shared.DTO.Base;

namespace eRents.Shared.DTO.Response
{
	public class BookingSummaryResponse : BaseResponse
	{
		// Direct booking entity fields - use exact entity field names
		public int BookingId { get; set; }
		public int PropertyId { get; set; }
		public DateTime StartDate { get; set; }
		public DateTime? EndDate { get; set; }
		public decimal TotalPrice { get; set; }
		public string Currency { get; set; } = "BAM";
		public int NumberOfGuests { get; set; } = 1;
		public string PaymentMethod { get; set; } = "PayPal";
		public string? PaymentStatus { get; set; }
		
				// Fields from other entities - use "EntityName + FieldName" pattern
		public string? PropertyName { get; set; } // Property.Name
		public int? PropertyImageId { get; set; } // Property.CoverImageId
		public string? BookingStatusName { get; set; } // BookingStatus.StatusName
		public string? UserFirstName { get; set; } // User.FirstName
		public string? UserLastName { get; set; } // User.LastName
		public string? UserEmail { get; set; } // User.Email
		
		// Computed properties for UI convenience
		public string Status => BookingStatusName ?? "Unknown";
		public string? TenantName => 
			!string.IsNullOrEmpty(UserFirstName) || !string.IsNullOrEmpty(UserLastName)
			? $"{UserFirstName} {UserLastName}".Trim()
			: null;
		public string? TenantEmail => UserEmail;
	}
}