namespace eRents.Shared.SearchObjects
{
	public class LocationSearchObject : BaseSearchObject
	{
		public string? City { get; set; }
		public string? State { get; set; }
		public string? Country { get; set; }
		public decimal? Latitude { get; set; }
		public decimal? Longitude { get; set; }
		public decimal? Radius { get; set; }
	}
}

