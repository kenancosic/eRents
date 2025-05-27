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
