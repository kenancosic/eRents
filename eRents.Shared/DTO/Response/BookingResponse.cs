using System;

namespace eRents.Shared.DTO.Response
{
	public class BookingResponse
	{
		public string BookingId { get; set; }
		public string PropertyId { get; set; }
		public string UserId { get; set; }
		public DateTime StartDate { get; set; }
		public DateTime EndDate { get; set; }
		public decimal TotalPrice { get; set; }
		public string Status { get; set; }
		public DateTime DateBooked { get; set; }
		public string PropertyName { get; set; }
		public string Currency { get; set; }
	}
}
