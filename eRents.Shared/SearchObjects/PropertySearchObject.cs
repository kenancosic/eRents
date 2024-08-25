using eRents.Shared.SearchObjects;

namespace eRents.Shared.SearchObjects
{
	public class PropertySearchObject : BaseSearchObject
	{
		public string? Name { get; set; }
		public int? CityId { get; set; }
		public int? OwnerId { get; set; }
		public decimal? MinPrice { get; set; }
		public decimal? MaxPrice { get; set; }
		public string? Status { get; set; }
		public int? MinNumberOfTenants { get; set; }
		public int? MaxNumberOfTenants { get; set; }
		public decimal? MinRating { get; set; }
		public decimal? MaxRating { get; set; }
		public DateTime? DateAddedFrom { get; set; }
		public DateTime? DateAddedTo { get; set; }
		public decimal? Latitude { get; set; }
		public decimal? Longitude { get; set; }
		public decimal? Radius { get; set; }
		public string? SortBy { get; set; }
		public bool SortDescending { get; set; } = false;
	}

}
