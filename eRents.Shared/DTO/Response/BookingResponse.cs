using System;
using eRents.Shared.DTO.Base;

namespace eRents.Shared.DTO.Response
{
	public class BookingResponse : BaseResponse
	{
		// Direct booking entity fields - use exact entity field names
		public int BookingId { get; set; }
		public int PropertyId { get; set; }
		public int UserId { get; set; }
		public DateTime StartDate { get; set; }
		public DateTime EndDate { get; set; }
		public decimal TotalPrice { get; set; }
		public DateTime BookingDate { get; set; }
		public string Currency { get; set; }
		public string PaymentMethod { get; set; } = "PayPal";
		public string? PaymentStatus { get; set; }  // "Pending", "Completed", "Failed"
		public string? PaymentReference { get; set; }  // PayPal Transaction ID
		public int NumberOfGuests { get; set; } = 1;
		public string? SpecialRequests { get; set; }
		
		// Fields from other entities - use "EntityName + FieldName" pattern
		public string? PropertyName { get; set; } // Property.Name
		public string? BookingStatusName { get; set; } // BookingStatus.StatusName
		public string? UserFirstName { get; set; }  // User.FirstName
		public string? UserLastName { get; set; }   // User.LastName
		public string? UserEmail { get; set; }      // User.Email
		
		// Computed properties for UI convenience (for backward compatibility)
		public string Status => BookingStatusName ?? "Unknown";
		public string? FirstName => UserFirstName;
		public string? LastName => UserLastName;
		public string? Email => UserEmail;
	}
}
