using System;
using eRents.Features.Core.Models;

namespace eRents.Features.PaymentManagement.Models;

public class PaymentSearch : BaseSearchObject
{
    public int? TenantId { get; set; }
    public int? PropertyId { get; set; }
    public int? BookingId { get; set; }

    public string? PaymentStatus { get; set; }
    public string? PaymentType { get; set; }

    public decimal? MinAmount { get; set; }
    public decimal? MaxAmount { get; set; }

    public DateTime? CreatedFrom { get; set; }
    public DateTime? CreatedTo { get; set;}
    // SortBy: amount | createdat | updatedat (default PaymentId)
}