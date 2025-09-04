using System;
using System.Collections.Generic;
using eRents.Domain.Models.Enums;
using eRents.Domain.Shared;

namespace eRents.Domain.Models;

public partial class Tenant : BaseEntity
{
    public int TenantId { get; set; }

    public int UserId { get; set; }

    public int? PropertyId { get; set; }

    public DateOnly? LeaseStartDate { get; set; }

    public DateOnly? LeaseEndDate { get; set; }

    public TenantStatusEnum TenantStatus { get; set; } = TenantStatusEnum.Active;

    public virtual User User { get; set; } = null!;

    public virtual ICollection<Payment> Payments { get; set; } = new List<Payment>();

    public virtual Property? Property { get; set; }

    public virtual ICollection<Subscription> Subscriptions { get; set; } = new List<Subscription>();
}
