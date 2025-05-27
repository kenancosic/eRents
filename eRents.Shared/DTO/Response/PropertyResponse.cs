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
		public int? PropertyTypeId { get; set; }
		public string? Type { get; set; }
		public int? StatusId { get; set; }
		public string? Status { get; set; }
		public int? RentingTypeId { get; set; }
		public string? RentingType { get; set; }
		public int? OwnerId { get; set; }
		public string? OwnerName { get; set; }
		public AddressDetailDto? AddressDetail { get; set; }
		public GeoRegionDto? GeoRegion { get; set; }
		public List<AmenityResponse>? Amenities { get; set; }
		public double? AverageRating { get; set; }
		public List<ImageResponse> Images { get; set; }  // List of images related to the property
		public int? Bedrooms { get; set; }
		public int? Bathrooms { get; set; }
		public decimal? Area { get; set; }
		public decimal? DailyRate { get; set; }
		public int? MinimumStayDays { get; set; }
		public DateTime? DateAdded { get; set; }
	}
}
