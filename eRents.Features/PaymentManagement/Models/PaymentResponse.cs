using System;

namespace eRents.Features.PaymentManagement.Models;

public class PaymentResponse
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

    public string? PaymentType { get; set; }
    public int? OriginalPaymentId { get; set; }
    public string? RefundReason { get; set; }

    // Tenant info (for display purposes)
    public TenantInfo? Tenant { get; set; }

    // Audit from BaseEntity
    public DateTime CreatedAt { get; set; }
    public string CreatedBy { get; set; } = string.Empty;
    public DateTime UpdatedAt { get; set; }
    public string? UpdatedBy { get; set; }
}

/// <summary>
/// Lightweight tenant info for payment responses
/// </summary>
public class TenantInfo
{
    public int TenantId { get; set; }
    public int? UserId { get; set; }
    public string? FirstName { get; set; }
    public string? LastName { get; set; }
    public string? Email { get; set; }
    public string FullName => $"{FirstName} {LastName}".Trim();
}