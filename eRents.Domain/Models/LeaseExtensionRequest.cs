using System;
using System.ComponentModel.DataAnnotations;

namespace eRents.Domain.Models;

public partial class LeaseExtensionRequest
{
    public int RequestId { get; set; }

    public int BookingId { get; set; }

    public int PropertyId { get; set; }

    public int TenantId { get; set; }

    public DateTime? NewEndDate { get; set; }  // null for indefinite extension

    public DateTime? NewMinimumStayEndDate { get; set; }

    [Required]
    public string Reason { get; set; } = null!;

    [Required]
    public string Status { get; set; } = "Pending";  // Pending, Approved, Rejected, Cancelled

    public DateTime DateRequested { get; set; }

    public DateTime? DateResponded { get; set; }

    public string? LandlordResponse { get; set; }

    public string? LandlordReason { get; set; }

    // Navigation properties
    public virtual Booking Booking { get; set; } = null!;

    public virtual Property Property { get; set; } = null!;

    public virtual Tenant Tenant { get; set; } = null!;
} 