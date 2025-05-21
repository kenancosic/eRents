using System;

namespace eRents.Shared.DTO.Requests
{
	public class BookingUpdateRequest
	{
		public DateTime? StartDate { get; set; }
		public DateTime? EndDate { get; set; }
		public decimal? TotalPrice { get; set; }
		public string? Status { get; set; }
	}
}