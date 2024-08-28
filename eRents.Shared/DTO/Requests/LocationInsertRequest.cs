namespace eRents.Shared.DTO.Requests
{
	public class LocationInsertRequest
	{
		public string City { get; set; } = null!;
		public string? State { get; set; }
		public string? Country { get; set; }
		public string? PostalCode { get; set; }
		public decimal? Latitude { get; set; }
		public decimal? Longitude { get; set; }
	}
}

