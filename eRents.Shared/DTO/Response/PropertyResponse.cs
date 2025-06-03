using System;
using System.Collections.Generic;
using eRents.Shared.DTO.Base;

namespace eRents.Shared.DTO.Response
{
	public class PropertyResponse : BaseResponse
	{
		// Core property data
		public string Name { get; set; }
		public string Description { get; set; }
		public decimal Price { get; set; }
		public string Currency { get; set; } = "BAM";
		
		// Foreign key references only (not redundant display names)
		public int PropertyTypeId { get; set; }
		public int StatusId { get; set; }
		public int RentingTypeId { get; set; }
		public int OwnerId { get; set; }
		
		// Physical details
		public int? Bedrooms { get; set; }
		public int? Bathrooms { get; set; }
		public decimal? Area { get; set; }
		public decimal? DailyRate { get; set; }
		public int? MinimumStayDays { get; set; }
		
		// Relationships (simplified - just IDs for base response)
		public AddressDetailResponse? AddressDetail { get; set; }
		public List<int> AmenityIds { get; set; } = new List<int>();
		public List<int> ImageIds { get; set; } = new List<int>();
	}
}
