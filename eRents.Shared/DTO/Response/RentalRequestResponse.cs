using System;

namespace eRents.Shared.DTO.Response
{
    /// <summary>
    /// Response DTO for rental request data
    /// </summary>
    public class RentalRequestResponse
    {
        // Direct entity fields - use exact entity property names
        public int RequestId { get; set; }
        public int PropertyId { get; set; }
        public int UserId { get; set; }
        public DateOnly ProposedStartDate { get; set; }
        public int LeaseDurationMonths { get; set; }
        public decimal ProposedMonthlyRent { get; set; }
        public string? Message { get; set; }
        public string Status { get; set; } = "Pending";
        public DateTime RequestDate { get; set; }
        public DateTime? ResponseDate { get; set; }
        public string? LandlordResponse { get; set; }

        // Calculated properties
        public DateOnly ProposedEndDate => ProposedStartDate.AddMonths(LeaseDurationMonths);

        // ✅ FIXED: Fields from other entities - use "EntityName + FieldName" pattern
        public string? PropertyName { get; set; }               // → Property.Name
        public string? PropertyAddressCity { get; set; }        // → Property.Address.City  
        public string? PropertyAddressCountry { get; set; }     // → Property.Address.Country
        public string? UserFirstName { get; set; }             // → User.FirstName
        public string? UserLastName { get; set; }              // → User.LastName
        public string? UserEmail { get; set; }                 // → User.Email
        public string? UserPhoneNumber { get; set; }           // → User.PhoneNumber

        // Computed properties for UI convenience (for backward compatibility)
        public string? UserFullName => !string.IsNullOrEmpty(UserFirstName) || !string.IsNullOrEmpty(UserLastName) 
            ? $"{UserFirstName} {UserLastName}".Trim() 
            : null;
        public string? PropertyLocation => !string.IsNullOrEmpty(PropertyAddressCity) && !string.IsNullOrEmpty(PropertyAddressCountry)
            ? $"{PropertyAddressCity}, {PropertyAddressCountry}"
            : PropertyAddressCity ?? PropertyAddressCountry ?? "Unknown Location";

        // Audit fields
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
        public string? CreatedBy { get; set; }
        public string? ModifiedBy { get; set; }
    }
} 