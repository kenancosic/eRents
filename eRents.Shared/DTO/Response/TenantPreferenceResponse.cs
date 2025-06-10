using System;
using System.Collections.Generic;
using eRents.Shared.DTO.Base;

namespace eRents.Shared.DTO.Response
{
    public class TenantPreferenceResponse : BaseResponse
    {
        // Direct tenant preference entity fields - use exact entity field names
        public int UserId { get; set; }
        public DateTime SearchStartDate { get; set; }
        public DateTime? SearchEndDate { get; set; }
        public decimal? MinPrice { get; set; }
        public decimal? MaxPrice { get; set; }
        public string City { get; set; } = null!;
        public List<string> Amenities { get; set; } = new List<string>();
        public string Description { get; set; } = string.Empty;
        public bool IsActive { get; set; }
        
        // Fields from other entities - use "EntityName + FieldName" pattern
        public string? UserFirstName { get; set; }   // User's first name
        public string? UserLastName { get; set; }    // User's last name
        public string? UserEmail { get; set; }       // User's email
        public string? UserPhoneNumber { get; set; } // User's phone number
        public string? UserCity { get; set; }        // User's city from address
        public string? ProfileImageUrl { get; set; } // Profile image URL
        
        // Match scoring for landlord tenant discovery
        public double MatchScore { get; set; }
        public List<string> MatchReasons { get; set; } = new List<string>();
        
        // Computed properties for UI convenience (for backward compatibility)
        public string? UserFullName { get; set; }
        public string? UserPhone { get; set; }
    }
} 