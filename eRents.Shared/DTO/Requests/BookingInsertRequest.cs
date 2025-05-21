using System;

namespace eRents.Shared.DTO.Requests
{
	public class BookingInsertRequest
	{
		public string PropertyId { get; set; }
		public string UserId { get; set; }
		public DateTime StartDate { get; set; }
		public DateTime EndDate { get; set; }
		public decimal TotalPrice { get; set; }
		public string? PaymentMethod { get; set; }
		public int NumberOfGuests { get; set; }
		public string? SpecialRequests { get; set; }
	}
}