namespace eRents.Shared.SearchObjects
{
	public class PropertySearchObject : BaseSearchObject
	{
		// ✅ AUTOMATIC: Direct property matches (exact entity property names)
		public string? Name { get; set; }              // → entity.Name
		public int? OwnerId { get; set; }              // → entity.OwnerId
		public string? Description { get; set; }       // → entity.Description
		public string? Status { get; set; }            // → entity.Status
		public string? Currency { get; set; }          // → entity.Currency
		public int? PropertyTypeId { get; set; }       // → entity.PropertyTypeId
		public int? RentingTypeId { get; set; }        // → entity.RentingTypeId
		public int? Bedrooms { get; set; }             // → entity.Bedrooms
		public int? Bathrooms { get; set; }            // → entity.Bathrooms
		public int? MinimumStayDays { get; set; }      // → entity.MinimumStayDays

		// ✅ AUTOMATIC: Range filtering (Min/Max pairs)
		public decimal? MinPrice { get; set; }         // → entity.Price >=
		public decimal? MaxPrice { get; set; }         // → entity.Price <=
		public decimal? MinArea { get; set; }          // → entity.Area >=
		public decimal? MaxArea { get; set; }          // → entity.Area <=
		public decimal? MinDailyRate { get; set; }     // → entity.DailyRate >=
		public decimal? MaxDailyRate { get; set; }     // → entity.DailyRate <=
		public int? MinBedrooms { get; set; }          // → entity.Bedrooms >=
		public int? MaxBedrooms { get; set; }          // → entity.Bedrooms <=
		public int? MinBathrooms { get; set; }         // → entity.Bathrooms >=
		public int? MaxBathrooms { get; set; }         // → entity.Bathrooms <=
		public DateTime? MinDateAdded { get; set; }    // → entity.DateAdded >=
		public DateTime? MaxDateAdded { get; set; }    // → entity.DateAdded <=

		// ⚙️ HELPER: Navigation properties (require custom implementation)
		public string? CityName { get; set; }          // → entity.Address.City
		public string? StateName { get; set; }         // → entity.Address.State
		public string? CountryName { get; set; }       // → entity.Address.Country
		public List<int>? AmenityIds { get; set; }     // → entity.Amenities (many-to-many)
		
		// ⚙️ HELPER: Complex filtering (require custom implementation)
		public decimal? MinRating { get; set; }        // → entity.Reviews.Average(r => r.StarRating)
		public decimal? MaxRating { get; set; }        // → entity.Reviews.Average(r => r.StarRating)
		
		// ⚙️ HELPER: Geolocation filtering (require custom implementation)
		public decimal? Latitude { get; set; }         // → entity.Address.Latitude
		public decimal? Longitude { get; set; }        // → entity.Address.Longitude
		public decimal? Radius { get; set; }           // → Distance calculation

		// DEPRECATED: Keeping for backward compatibility (remove in next version)
		[Obsolete("Use MinBedrooms/MaxBedrooms instead")]
		public int? MinNumberOfTenants { get; set; }
		[Obsolete("Use MinBedrooms/MaxBedrooms instead")]
		public int? MaxNumberOfTenants { get; set; }
		[Obsolete("Use MinDateAdded/MaxDateAdded instead")]
		public DateTime? DateAddedFrom { get; set; }
		[Obsolete("Use MinDateAdded/MaxDateAdded instead")]
		public DateTime? DateAddedTo { get; set; }

		// Note: SortBy and SortDescending are now inherited from BaseSearchObject
		// SortBy supports: "Price", "Name", "DateAdded", "Area", "DailyRate", etc.
	}
}
