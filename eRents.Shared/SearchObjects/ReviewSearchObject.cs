using eRents.Shared.SearchObjects;

namespace eRents.Shared.SearchObjects
{
	public class ReviewSearchObject : BaseSearchObject
	{
		public int? PropertyId { get; set; }
		public int? TenantId { get; set; }
		public decimal? MinRating { get; set; }
		public decimal? MaxRating { get; set; }
		public string? SortBy { get; set; }  // "Date" or "Rating"
		public bool SortDescending { get; set; }  // True for descending
	}
}
