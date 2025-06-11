using System;
using eRents.Shared.DTO.Base;

namespace eRents.Shared.DTO.Response
{
    public class PropertyOfferResponse : BaseResponse
    {
        // Direct property offer entity fields - use exact entity field names
        public int OfferId { get; set; }
        public int TenantId { get; set; } // Use UserController to fetch tenant details
        public int PropertyId { get; set; } // Use PropertiesController to fetch property details
        public int LandlordId { get; set; } // Use UserController to fetch landlord details
        public DateTime DateOffered { get; set; }
        public string Status { get; set; } = "Pending"; // Pending, Accepted, Rejected, Expired
        public string? Message { get; set; }
        
        		// Fields from other entities - use "EntityName + FieldName" pattern
		public string? PropertyName { get; set; }        // Property.Name
		public decimal? PropertyPrice { get; set; }      // Property.Price
		public string? UserFirstNameTenant { get; set; } // User.FirstName (tenant role)
		public string? UserLastNameTenant { get; set; }  // User.LastName (tenant role)
		public string? UserEmailTenant { get; set; }     // User.Email (tenant role)
		public string? UserFirstNameLandlord { get; set; } // User.FirstName (landlord role)
		public string? UserLastNameLandlord { get; set; }  // User.LastName (landlord role)
        
        // Computed properties for UI convenience (for backward compatibility)
        public string? PropertyTitle => PropertyName; // Alias for backward compatibility
        public string? TenantFullName => 
            !string.IsNullOrEmpty(UserFirstNameTenant) || !string.IsNullOrEmpty(UserLastNameTenant)
                ? $"{UserFirstNameTenant} {UserLastNameTenant}".Trim()
                : null;
        public string? TenantEmail => UserEmailTenant; // Alias for backward compatibility
        public string? LandlordFullName => 
            !string.IsNullOrEmpty(UserFirstNameLandlord) || !string.IsNullOrEmpty(UserLastNameLandlord)
                ? $"{UserFirstNameLandlord} {UserLastNameLandlord}".Trim()
                : null;
    }
} 