using System;
using System.ComponentModel.DataAnnotations;
using eRents.Shared.DTO.Base;

namespace eRents.Shared.DTO.Requests
{
    /// <summary>
    /// Request DTO for updating/responding to rental requests (primarily for landlord responses)
    /// </summary>
    public class RentalRequestUpdateRequest : BaseUpdateRequest
    {
        [Required]
        [RegularExpression("^(Pending|Approved|Rejected)$", ErrorMessage = "Status must be Pending, Approved, or Rejected")]
        public string Status { get; set; } = "Pending";

        [MaxLength(1000, ErrorMessage = "Landlord response cannot exceed 1000 characters")]
        public string? LandlordResponse { get; set; }

        public DateTime? ResponseDate { get; set; }

        // Optional fields for modifying the request (if status is still Pending)
        public DateOnly? ProposedStartDate { get; set; }

        [Range(6, 60, ErrorMessage = "Lease duration must be between 6 and 60 months")]
        public int? LeaseDurationMonths { get; set; }

        [Range(1, 50000, ErrorMessage = "Monthly rent must be between 1 and 50,000 BAM")]
        public decimal? ProposedMonthlyRent { get; set; }

        [MaxLength(1000, ErrorMessage = "Message cannot exceed 1000 characters")]
        public string? Message { get; set; }
    }
} 