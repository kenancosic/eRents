using System;
using System.ComponentModel.DataAnnotations;
using eRents.Shared.DTO.Response;

namespace eRents.Shared.DTO.Requests
{
	public class PropertyInsertRequest
	{
		public string? Name { get; set; }
		public int? PropertyTypeId { get; set; }
		public string? Status { get; set; }
		public int? RentingTypeId { get; set; }
		public string? Description { get; set; }
		public decimal Price { get; set; }
		public string Currency { get; set; } = "BAM";
		public int? Bedrooms { get; set; }
		public int? Bathrooms { get; set; }
		public decimal? Area { get; set; }
		public decimal? DailyRate { get; set; }
		public int? MinimumStayDays { get; set; }
		public int OwnerId { get; set; }
		public AddressDetailDto? AddressDetail { get; set; }
		public List<int>? AmenityIds { get; set; }
		public List<int>? ImageIds { get; set; } // IDs of uploaded images
		public List<string>? AmenityNames { get; set; }
	}
}
