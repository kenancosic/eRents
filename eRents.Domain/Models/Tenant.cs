using System;
using System.Collections.Generic;

namespace eRents.Domain.Models;

public partial class Tenant
{
    public int TenantId { get; set; }

    public string Name { get; set; } = null!;

    public string? ContactInfo { get; set; }

    public DateOnly? DateOfBirth { get; set; }

    public int? PropertyId { get; set; }

    public DateOnly? LeaseStartDate { get; set; }

    public string? TenantStatus { get; set; }

    public virtual ICollection<Payment> Payments { get; set; } = new List<Payment>();

    public virtual Property? Property { get; set; }

    public virtual ICollection<Review> Reviews { get; set; } = new List<Review>();
}
