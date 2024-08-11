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
	}
}
