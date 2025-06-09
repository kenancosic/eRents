using System;
using eRents.Shared.DTO.Base;

namespace eRents.Shared.DTO.Requests
{
	public class BookingInsertRequest : BaseInsertRequest
	{
		public int PropertyId { get; set; }
		public int UserId { get; set; }
		public DateTime StartDate { get; set; }
		public DateTime EndDate { get; set; }
		
		public decimal TotalPrice { get; set; }
		public string PaymentMethod { get; set; } = "PayPal";
		public string Currency { get; set; } = "BAM";
		public int NumberOfGuests { get; set; } = 1;
		public string? SpecialRequests { get; set; }
		
		// Enhanced payment tracking
		public string? PaymentReference { get; set; }
		public string? PaymentStatus { get; set; } = "Pending";
	}
}