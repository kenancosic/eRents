using System;

namespace eRents.Shared.DTO.Response
{
	public class BookingSummaryDto
	{
		public int BookingId { get; set; }
		public int PropertyId { get; set; }
		public string PropertyName { get; set; }
		public int? PropertyImageId { get; set; }
		public byte[] PropertyImageData { get; set; }
		public DateTime StartDate { get; set; }
		public DateTime? EndDate { get; set; }
		public decimal TotalPrice { get; set; }
		public string Currency { get; set; }
		public string BookingStatus { get; set; }
	}
}