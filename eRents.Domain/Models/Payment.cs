using System;
using System.Collections.Generic;
using eRents.Domain.Shared;

namespace eRents.Domain.Models;

public partial class Payment : BaseEntity
{
    public int PaymentId { get; set; }

    public int? TenantId { get; set; }

    public int? PropertyId { get; set; }

    public int? BookingId { get; set; }

    public int? SubscriptionId { get; set; }

    public decimal Amount { get; set; }

    public string? Currency { get; set; }

    public string? PaymentMethod { get; set; }

    public string? PaymentStatus { get; set; }

    public string? PaymentReference { get; set; }

    // Stripe payment fields
    public string? StripePaymentIntentId { get; set; }
    
    public string? StripeChargeId { get; set; }

    // Additional fields for refund support
    public int? OriginalPaymentId { get; set; }
    
    public string? RefundReason { get; set; }
    
    public string? PaymentType { get; set; } = "BookingPayment"; // BookingPayment, Refund

    // Navigation Properties
    public virtual Booking? Booking { get; set; }

    public virtual Property? Property { get; set; }

    public virtual Tenant? Tenant { get; set; }
    
    public virtual Subscription? Subscription { get; set; }
    
    public virtual Payment? OriginalPayment { get; set; }
    
    public virtual ICollection<Payment> Refunds { get; set; } = new List<Payment>();
}
