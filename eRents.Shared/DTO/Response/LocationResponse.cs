using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eRents.Shared.DTO.Response
{
	public class LocationResponse
	{
		public int LocationId { get; set; }
		public string City { get; set; } = null!;
		public string? State { get; set; }
		public string? Country { get; set; }
		public string? PostalCode { get; set; }
		public decimal? Latitude { get; set; }
		public decimal? Longitude { get; set; }
	}
}
