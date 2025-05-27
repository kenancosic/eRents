using System;

namespace eRents.Shared.DTO.Response
{
	public class GeoRegionDto
	{
		public string City { get; set; }
		public string? State { get; set; }
		public string Country { get; set; }
		public string? PostalCode { get; set; }
	}
} 