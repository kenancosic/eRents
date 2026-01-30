using System;
using eRents.Domain.Models.Enums;

namespace eRents.Features.BookingManagement.Models;

public class FinancialReportResponse
{
    public int BookingId { get; set; }
    public string PropertyName { get; set; } = string.Empty;
    public string TenantName { get; set; } = string.Empty;
    public DateTime StartDate { get; set; }
    public DateTime? EndDate { get; set; }
    public RentalType? RentalType { get; set; }
    public decimal TotalPrice { get; set; }
    public string Currency { get; set; } = "USD";
    public BookingStatusEnum Status { get; set; }
    
    // Cancellation/Refund fields
    public decimal RefundAmount { get; set; }
    public bool WasRefunded => RefundAmount > 0;
    public decimal NetRevenue => TotalPrice - RefundAmount;
    
    // Grouping fields (populated when grouped)
    public string? GroupKey { get; set; }
    public string? GroupLabel { get; set; }
    public decimal? GroupTotal { get; set; }
    public int? GroupCount { get; set; }
}

public class FinancialReportSummary
{
    public List<FinancialReportResponse> Reports { get; set; } = new();
    public decimal TotalRevenue { get; set; }
    public int TotalBookings { get; set; }
    public decimal AverageBookingValue { get; set; }
    public Dictionary<string, decimal> GroupTotals { get; set; } = new();
    public int TotalPages { get; set; }
    public int CurrentPage { get; set; }
    public int PageSize { get; set; }
    
    // Cancellation/Refund summary
    public int TotalCancellations { get; set; }
    public decimal TotalRefunds { get; set; }
    public decimal NetRevenue { get; set; }
}
