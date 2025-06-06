using System;
using eRents.Shared.DTO.Base;

namespace eRents.Shared.DTO.Response
{
	public class BookingResponse : BaseResponse
	{
		public int BookingId { get; set; }
		public int PropertyId { get; set; }
		public int UserId { get; set; }
		public DateTime StartDate { get; set; }
		public DateTime EndDate { get; set; }
		public decimal TotalPrice { get; set; }
		public string Status { get; set; }
		public DateTime BookingDate { get; set; }
		public string PropertyName { get; set; } // Could be fetched from PropertiesController using PropertyId
		public string Currency { get; set; }
		
		// New Payment Information fields
		public string PaymentMethod { get; set; } = "PayPal";
		public string? PaymentStatus { get; set; }  // "Pending", "Completed", "Failed"
		public string? PaymentReference { get; set; }  // PayPal Transaction ID
		
		// New Booking Info fields
		public int NumberOfGuests { get; set; } = 1;
		public string? SpecialRequests { get; set; }
	}
}
