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
        public string? PropertyName { get; set; }        // Property name
        public decimal? PropertyPrice { get; set; }      // Property price
        public string? UserFirstNameTenant { get; set; } // Tenant's first name
        public string? UserLastNameTenant { get; set; }  // Tenant's last name
        public string? UserEmailTenant { get; set; }     // Tenant's email
        public string? UserFirstNameLandlord { get; set; } // Landlord's first name
        public string? UserLastNameLandlord { get; set; }  // Landlord's last name
        
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