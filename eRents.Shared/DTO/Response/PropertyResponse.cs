using System;
using System.Collections.Generic;

namespace eRents.Shared.DTO.Response
{
	public class PropertyResponse
	{
		// Corresponds to the Property entity
		public string PropertyId { get; set; }
		public string Name { get; set; }
		public string Description { get; set; }
		public decimal Price { get; set; }
		public string Currency { get; set; } = "BAM";
		public string Address { get; set; }
		public DateTime DateListed { get; set; }
		public string? CityName { get; set; }  // City is now retrieved from the Location entity
		public string? StateName { get; set; } // State is now retrieved from the Location entity
		public string? CountryName { get; set; } // Country is now retrieved from the Location entity
		public string? OwnerName { get; set; }
		public List<string>? Amenities { get; set; }
		public double? AverageRating { get; set; }
		public List<ImageResponse> Images { get; set; }  // List of images related to the property
		public int? Bedrooms { get; set; }
		public int? Bathrooms { get; set; }
		public decimal? Area { get; set; }

		public PropertyResponse()
		{
			Images = new List<ImageResponse>();
		}
	}
}
