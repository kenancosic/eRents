using System;

namespace eRents.Shared.DTO.Response
{
	public class PropertySummaryDto
	{
		public int PropertyId { get; set; }
		public string Name { get; set; }
		public string LocationString { get; set; }
		public decimal Price { get; set; }
		public double? AverageRating { get; set; }
		public int ReviewCount { get; set; }
		public int? CoverImageId { get; set; }
		public byte[] CoverImageData { get; set; }
		public int? Rooms { get; set; }
		public decimal? Area { get; set; }
		public string Currency { get; set; } = "BAM";
		public string? Type { get; set; }
		public string? Status { get; set; }
		public string? RentingType { get; set; }
		public string? ThumbnailUrl { get; set; }
	}
}