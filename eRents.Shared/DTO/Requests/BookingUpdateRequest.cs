using System;
using eRents.Shared.DTO.Base;

namespace eRents.Shared.DTO.Requests
{
	public class BookingUpdateRequest : BaseUpdateRequest
	{
		public DateTime? StartDate { get; set; }
		public DateTime? EndDate { get; set; }
		public decimal? TotalPrice { get; set; }
		public string? Status { get; set; }
	}
}