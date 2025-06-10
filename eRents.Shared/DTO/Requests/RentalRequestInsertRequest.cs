using System;
using System.ComponentModel.DataAnnotations;
using eRents.Shared.DTO.Base;

namespace eRents.Shared.DTO.Requests
{
    /// <summary>
    /// Request DTO for creating a new annual rental request
    /// </summary>
    public class RentalRequestInsertRequest : BaseInsertRequest
    {
        [Required]
        public int PropertyId { get; set; }

        [Required]
        public DateOnly ProposedStartDate { get; set; }

        [Required]
        [Range(6, 60, ErrorMessage = "Lease duration must be between 6 and 60 months")]
        public int LeaseDurationMonths { get; set; } = 12; // Default to 12 months

        [Required]
        [Range(1, 50000, ErrorMessage = "Monthly rent must be between 1 and 50,000 BAM")]
        public decimal ProposedMonthlyRent { get; set; }

        [MaxLength(1000, ErrorMessage = "Message cannot exceed 1000 characters")]
        public string? Message { get; set; }

        // Calculated property helper
        public DateOnly ProposedEndDate => ProposedStartDate.AddMonths(LeaseDurationMonths);
    }
} 