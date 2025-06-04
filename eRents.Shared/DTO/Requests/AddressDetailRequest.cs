using System;

namespace eRents.Shared.DTO.Requests
{
	public class AddressDetailRequest
	{
		public string StreetLine1 { get; set; }
		public string? StreetLine2 { get; set; }
		public int? GeoRegionId { get; set; }
		public GeoRegionRequest? GeoRegion { get; set; }
		public decimal? Latitude { get; set; }
		public decimal? Longitude { get; set; }
	}

	public class GeoRegionRequest
	{
		public string City { get; set; } = string.Empty;
		public string? State { get; set; }
		public string Country { get; set; } = string.Empty;
		public string? PostalCode { get; set; }
	}
} 