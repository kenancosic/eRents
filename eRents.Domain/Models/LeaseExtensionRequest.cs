using System;
using eRents.Domain.Shared;
using eRents.Domain.Models.Enums;

namespace eRents.Domain.Models;

public class LeaseExtensionRequest : BaseEntity
{
    public int LeaseExtensionRequestId { get; set; }
    public int BookingId { get; set; }
    public int RequestedByUserId { get; set; }

    public DateOnly? OldEndDate { get; set; }
    public DateOnly? NewEndDate { get; set; }
    public int? ExtendByMonths { get; set; }
    public decimal? NewMonthlyAmount { get; set; }

    public string? Reason { get; set; }
    public LeaseExtensionStatusEnum Status { get; set; } = LeaseExtensionStatusEnum.Pending;

    public int? RespondedByUserId { get; set; }
    public DateTime? RespondedAt { get; set; }

    public virtual Booking Booking { get; set; } = null!;
}
