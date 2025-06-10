using System;
using System.Collections.Generic;

namespace eRents.Shared.DTO.Response
{
	public class MaintenanceIssueResponse
	{
		public int MaintenanceIssueId { get; set; }
		public int PropertyId { get; set; }
		public int TenantId { get; set; }
		public string Title { get; set; }
		public string Description { get; set; }
		public string Priority { get; set; }
		public string Status { get; set; }
		public DateTime DateReported { get; set; }
		public DateTime? DateResolved { get; set; }
		public List<int> ImageIds { get; set; } = new List<int>();
		public string? LandlordResponse { get; set; }
		public DateTime? LandlordResponseDate { get; set; }
		public string? Category { get; set; }
		public bool RequiresInspection { get; set; }
		public bool IsTenantComplaint { get; set; }
		public decimal? Cost { get; set; }
		public string? ResolutionNotes { get; set; }
		
		// Fields from other entities - use "EntityName + FieldName" pattern
		public string? PropertyName { get; set; }        // Property name
		public string? PropertyAddress { get; set; }     // Property address for quick display
		public string? UserFirstNameTenant { get; set; } // Tenant's first name
		public string? UserLastNameTenant { get; set; }  // Tenant's last name
		public string? UserEmailTenant { get; set; }     // Tenant's email
		public string? UserFirstNameLandlord { get; set; } // Landlord's first name (property owner)
		public string? UserLastNameLandlord { get; set; }  // Landlord's last name (property owner)
		
		// Computed properties for UI convenience (for backward compatibility)
		public string? TenantName => 
			!string.IsNullOrEmpty(UserFirstNameTenant) || !string.IsNullOrEmpty(UserLastNameTenant)
				? $"{UserFirstNameTenant} {UserLastNameTenant}".Trim()
				: null;
		public string? LandlordName => 
			!string.IsNullOrEmpty(UserFirstNameLandlord) || !string.IsNullOrEmpty(UserLastNameLandlord)
				? $"{UserFirstNameLandlord} {UserLastNameLandlord}".Trim()
				: null;
	}
} 