namespace eRents.Shared.DTO.Response
{
	public class AddressDetailResponseDto
	{
		public int AddressDetailId { get; set; }
		public string StreetLine1 { get; set; } = null!;
		public string? StreetLine2 { get; set; }
		public decimal? Latitude { get; set; }
		public decimal? Longitude { get; set; }
		public GeoRegionResponseDto? GeoRegion { get; set; }
	}
}