using System;
using System.Collections.Generic;
using eRents.Shared.DTO.Base;

namespace eRents.Shared.DTO.Response
{
	public class PropertyResponse : BaseResponse
	{
		// Core property data
		public int PropertyId { get; set; }
		public string Name { get; set; }
		public string Description { get; set; }
		public decimal Price { get; set; }
		public string Currency { get; set; } = "BAM";
		public DateTime? DateAdded { get; set; }
		
		// Foreign key references
		public int PropertyTypeId { get; set; }
		public string Status { get; set; }
		public int RentingTypeId { get; set; }
		public int OwnerId { get; set; }
		
		// Physical details
		public int? Bedrooms { get; set; }
		public int? Bathrooms { get; set; }
		public decimal? Area { get; set; }
		public decimal? DailyRate { get; set; }
		public int? MinimumStayDays { get; set; }
		
		// Location
		public AddressResponse? Address { get; set; }
		
		// Related data - IDs only (frontend utilities will fetch full objects when needed)
		public List<int> AmenityIds { get; set; } = new List<int>();
		public List<int> ImageIds { get; set; } = new List<int>();
		
		// Optional display names - populated for detail views
		public string? PropertyTypeName { get; set; }
		public string? RentingTypeName { get; set; }
		public string? OwnerName { get; set; }
		public double? AverageRating { get; set; }
	}
}
