using System;
using System.Collections.Generic;

namespace eRents.Shared.SearchObjects
{
    /// <summary>
    /// Search object for filtering rental request queries
    /// </summary>
    public class RentalRequestSearchObject : BaseSearchObject
    {
        // ✅ AUTOMATIC: Direct property matches (exact entity property names)
        public int? RequestId { get; set; }               // → entity.RequestId
        public int? PropertyId { get; set; }              // → entity.PropertyId
        public int? UserId { get; set; }                  // → entity.UserId
        public string? Status { get; set; }               // → entity.Status
        public string? Message { get; set; }              // → entity.Message
        public string? LandlordResponse { get; set; }     // → entity.LandlordResponse

        // ✅ AUTOMATIC: Range filtering (Min/Max pairs)
        public DateOnly? MinProposedStartDate { get; set; }  // → entity.ProposedStartDate >=
        public DateOnly? MaxProposedStartDate { get; set; }  // → entity.ProposedStartDate <=
        public int? MinLeaseDurationMonths { get; set; }     // → entity.LeaseDurationMonths >=
        public int? MaxLeaseDurationMonths { get; set; }     // → entity.LeaseDurationMonths <=
        public decimal? MinProposedMonthlyRent { get; set; } // → entity.ProposedMonthlyRent >=
        public decimal? MaxProposedMonthlyRent { get; set; } // → entity.ProposedMonthlyRent <=
        public DateTime? MinRequestDate { get; set; }       // → entity.RequestDate >=
        public DateTime? MaxRequestDate { get; set; }       // → entity.RequestDate <=

        // ✅ FIXED: Navigation properties (require custom implementation) - follow EntityName + FieldName pattern
        public string? PropertyName { get; set; }            // → entity.Property.Name
        public string? PropertyAddressCity { get; set; }     // → entity.Property.Address.City
        public string? PropertyAddressCountry { get; set; }  // → entity.Property.Address.Country
        public string? UserFirstName { get; set; }           // → entity.User.FirstName
        public string? UserLastName { get; set; }            // → entity.User.LastName
        public string? UserEmail { get; set; }               // → entity.User.Email
        public string? UserPhoneNumber { get; set; }         // → entity.User.PhoneNumber

        // ⚙️ HELPER: Status filtering (marked as helper property)
        public List<string>? Statuses { get; set; }          // → entity.Status IN (...)

        // ⚙️ HELPER: Landlord-specific filtering (marked as helper property)
        public int? LandlordId { get; set; }                 // Filter by property owner
        public bool? PendingOnly { get; set; }               // Show only pending requests
        public bool? ExpiringRequests { get; set; }          // Show requests with start date approaching

        // ⚙️ HELPER: Computed search fields (marked as helper property)
        public string? UserFullName { get; set; }            // Combined first + last name search
        public string? PropertyLocation { get; set; }        // Combined city + country search
    }
} 