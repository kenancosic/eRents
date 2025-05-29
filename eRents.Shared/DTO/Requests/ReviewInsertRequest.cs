using System;
using System.Collections.Generic;

namespace eRents.Shared.DTO.Requests
{
	public class ReviewInsertRequest
	{
		public int? PropertyId { get; set; }
		public string? Description { get; set; }
		public decimal? StarRating { get; set; }
		public int? BookingId { get; set; }
		public List<int> ImageIds { get; set; } = new List<int>();
	}
}
