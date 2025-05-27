namespace eRents.Shared.DTO.Requests
{
	public class PropertyUpdateRequest
	{
		public string? Name { get; set; }
		public string? Description { get; set; }
		public decimal? Price { get; set; }
		public string? Currency { get; set; }
		public int? TypeId { get; set; }
		public int? StatusId { get; set; }
		public int? RentingTypeId { get; set; }
		public int? Bedrooms { get; set; }
		public int? Bathrooms { get; set; }
		public decimal? Area { get; set; }
		public decimal? DailyRate { get; set; }
		public int? MinimumStayDays { get; set; }
		public AddressDetailDto? AddressDetail { get; set; }
		public List<int>? AmenityIds { get; set; }
		public List<int>? ImageIds { get; set; }
	}

	public class AddressDetailDto
	{
		public string StreetLine1 { get; set; }
		public string? StreetLine2 { get; set; }
		public int? GeoRegionId { get; set; }
		public GeoRegionDto? GeoRegion { get; set; }
		public decimal? Latitude { get; set; }
		public decimal? Longitude { get; set; }
	}

	public class GeoRegionDto
	{
		public string City { get; set; }
		public string? State { get; set; }
		public string Country { get; set; }
		public string? PostalCode { get; set; }
	}
}
