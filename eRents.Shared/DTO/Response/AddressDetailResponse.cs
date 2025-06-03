using System;
using eRents.Shared.DTO.Base;

namespace eRents.Shared.DTO.Response
{
	public class AddressDetailResponse : BaseResponse
	{
		public string StreetLine1 { get; set; }
		public string? StreetLine2 { get; set; }
		public int? GeoRegionId { get; set; }
		public GeoRegionResponse? GeoRegion { get; set; }
		public decimal? Latitude { get; set; }
		public decimal? Longitude { get; set; }
	}
} 