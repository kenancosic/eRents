using System;

namespace eRents.Shared.DTO.Response
{
	public class AddressDetailDto
	{
		public string StreetLine1 { get; set; }
		public string? StreetLine2 { get; set; }
		public int? GeoRegionId { get; set; }
		public GeoRegionDto? GeoRegion { get; set; }
		public decimal? Latitude { get; set; }
		public decimal? Longitude { get; set; }
	}
} 