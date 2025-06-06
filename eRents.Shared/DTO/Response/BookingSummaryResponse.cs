using System;
using eRents.Shared.DTO.Base;

namespace eRents.Shared.DTO.Response
{
	public class BookingSummaryResponse : BaseResponse
	{
		public int BookingId { get; set; }
		public int PropertyId { get; set; }
		public string PropertyName { get; set; }
		public int? PropertyImageId { get; set; }
		public DateTime StartDate { get; set; }
		public DateTime? EndDate { get; set; }
		public decimal TotalPrice { get; set; }
		public string Currency { get; set; } = "BAM";
		public string Status { get; set; }
		public string? TenantName { get; set; }
		public string? TenantEmail { get; set; }
		
		// Additional booking details for management purposes
		public int NumberOfGuests { get; set; } = 1;
		public string PaymentMethod { get; set; } = "PayPal";
		public string? PaymentStatus { get; set; }
	}
}