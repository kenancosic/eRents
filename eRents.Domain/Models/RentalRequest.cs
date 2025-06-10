using System;
using System.ComponentModel.DataAnnotations;
using eRents.Domain.Shared;

namespace eRents.Domain.Models;

/// <summary>
/// Entity for NEW annual lease requests (different from LeaseExtensionRequest which extends existing leases)
/// </summary>
public partial class RentalRequest : BaseEntity
{
    public int RequestId { get; set; }

    public int PropertyId { get; set; }

    public int UserId { get; set; }  // User requesting to become tenant

    public DateOnly ProposedStartDate { get; set; }

    public int LeaseDurationMonths { get; set; } = 6; // Minimum 6 months

    public decimal ProposedMonthlyRent { get; set; }

    public string? Message { get; set; }

    [Required]
    public string Status { get; set; } = "Pending"; // Pending, Approved, Rejected

    public DateTime RequestDate { get; set; } = DateTime.UtcNow;

    public DateTime? ResponseDate { get; set; }

    public string? LandlordResponse { get; set; }

    // Navigation properties
    public virtual Property Property { get; set; } = null!;

    public virtual User User { get; set; } = null!;

    // Calculated property
    public DateOnly ProposedEndDate => ProposedStartDate.AddMonths(LeaseDurationMonths);
} 