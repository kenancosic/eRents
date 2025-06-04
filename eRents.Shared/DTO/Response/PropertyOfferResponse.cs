using System;
using eRents.Shared.DTO.Base;

namespace eRents.Shared.DTO.Response
{
    public class PropertyOfferResponse : BaseResponse
    {
        public int OfferId { get; set; }
        public int TenantId { get; set; } // Use UserController to fetch tenant details
        public int PropertyId { get; set; } // Use PropertiesController to fetch property details
        public int LandlordId { get; set; } // Use UserController to fetch landlord details
        public DateTime DateOffered { get; set; }
        public string Status { get; set; } = "Pending"; // Pending, Accepted, Rejected, Expired
        public string? Message { get; set; }
        
        // Essential display fields only (small data for list views)
        public string? PropertyTitle { get; set; } // Keep for quick display
        public decimal? PropertyPrice { get; set; } // Keep for offer context
        public string? TenantFullName { get; set; } // Keep for landlord notifications
        public string? TenantEmail { get; set; } // Keep for contact
    }
} 