using System;
using eRents.Domain.Models.Enums;
using eRents.Features.Core.Models;

namespace eRents.Features.BookingManagement.Models;

public class FinancialReportRequest : BaseSearchObject
{
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    
    // Grouping options
    public FinancialReportGroupBy? GroupBy { get; set; }
    
    public bool SortDescending { get; set; } = false;
    
    // Filtering options
    public int? PropertyId { get; set; }
    public RentalType? RentalType { get; set; }
    public BookingStatusEnum? BookingStatus { get; set; }
}

public enum FinancialReportGroupBy
{
    None = 0,
    Property = 1,
    Month = 2,
    RentalType = 3,
    Day = 4
}

public enum FinancialReportSortBy
{
    PropertyName = 0,
    TenantName = 1,
    StartDate = 2,
    EndDate = 3,
    TotalPrice = 4,
    RentalType = 5
}
