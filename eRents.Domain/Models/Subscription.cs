using System;
using System.Collections.Generic;
using eRents.Domain.Shared;
using eRents.Domain.Models.Enums;

namespace eRents.Domain.Models;

public partial class Subscription : BaseEntity
{
    public int SubscriptionId { get; set; }
    public int TenantId { get; set; }
    public int PropertyId { get; set; }
    public int BookingId { get; set; }
    
    // Monthly amount to charge
    public decimal MonthlyAmount { get; set; }
    public string Currency { get; set; } = "USD";
    
    // Subscription dates
    public DateOnly StartDate { get; set; }
    public DateOnly? EndDate { get; set; } // Optional for open-ended leases
    
    // Payment frequency
    public int PaymentDayOfMonth { get; set; } = 1; // Day of month to charge (1-28)
    
    // Status
    public SubscriptionStatusEnum Status { get; set; } = SubscriptionStatusEnum.Active;
    
    // Next payment date
    public DateOnly NextPaymentDate { get; set; }
    
    // Navigation properties
    public virtual Tenant Tenant { get; set; } = null!;
    public virtual Property Property { get; set; } = null!;
    public virtual Booking Booking { get; set; } = null!;
    public virtual ICollection<Payment> Payments { get; set; } = new List<Payment>();
}
