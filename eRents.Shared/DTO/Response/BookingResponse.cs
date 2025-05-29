using System;

namespace eRents.Shared.DTO.Response
{
	public class BookingResponse
	{
		public int BookingId { get; set; }
		public int PropertyId { get; set; }
		public int UserId { get; set; }
		public DateTime StartDate { get; set; }
		public DateTime EndDate { get; set; }
		public decimal TotalPrice { get; set; }
		public string Status { get; set; }
		public DateTime DateBooked { get; set; }
		public string PropertyName { get; set; }
		public string Currency { get; set; }
	}
}
