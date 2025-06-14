using System;
using System.Collections.Generic;
using eRents.Shared.DTO.Base;

namespace eRents.Shared.DTO.Response
{
	public class PropertyResponse : BaseResponse
	{
		// Direct property entity fields - use exact entity field names
		public int PropertyId { get; set; }
		public string Name { get; set; }
		public string Description { get; set; }
		public decimal Price { get; set; }
		public string Currency { get; set; } = "BAM";
		public DateTime? DateAdded { get; set; }
		public int PropertyTypeId { get; set; }
		public string Status { get; set; }
		public int RentingTypeId { get; set; }
		public int OwnerId { get; set; }
		public int? Bedrooms { get; set; }
		public int? Bathrooms { get; set; }
		public decimal? Area { get; set; }
		public int? MinimumStayDays { get; set; }
		
		// Location (nested object)
		public AddressResponse? Address { get; set; }
		
		// Related data - IDs only (frontend utilities will fetch full objects when needed)
		public List<int> AmenityIds { get; set; } = new List<int>();
		public List<int> ImageIds { get; set; } = new List<int>();
		
		// Fields from other entities - use "EntityName + FieldName" pattern
		public string? PropertyTypeName { get; set; }
		public string? RentingTypeName { get; set; }
		public string? UserFirstName { get; set; }  // Owner's first name
		public string? UserLastName { get; set; }   // Owner's last name
		public double? AverageRating { get; set; }  // Computed from reviews
		
		// Computed properties for UI convenience (for backward compatibility)
		public string? OwnerName => 
			!string.IsNullOrEmpty(UserFirstName) || !string.IsNullOrEmpty(UserLastName)
				? $"{UserFirstName} {UserLastName}".Trim()
				: null;
	}
}
