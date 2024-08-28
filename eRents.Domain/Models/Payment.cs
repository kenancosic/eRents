using System;
using System.Collections.Generic;

namespace eRents.Domain.Models;

public partial class Payment
{
    public int PaymentId { get; set; }

    public int? TenantId { get; set; }

    public int? PropertyId { get; set; }

    public decimal Amount { get; set; }

    public DateTime? DatePaid { get; set; }

    public string? PaymentMethod { get; set; }

    public string? PaymentStatus { get; set; }

    public string? PaymentReference { get; set; }

    public virtual Property? Property { get; set; }

    public virtual Tenant? Tenant { get; set; }
}
