using Microsoft.EntityFrameworkCore;
using eRents.Domain.Models;
using eRents.Features.BookingManagement.Models;
using eRents.Features.Shared.Services;
using eRents.Domain.Models.Enums;
using eRents.Features.Core;
using AutoMapper;
using Microsoft.Extensions.Logging;
using eRents.Domain.Shared.Interfaces;

namespace eRents.Features.BookingManagement.Services;

public interface IFinancialReportService
{
    Task<FinancialReportSummary> GetFinancialReportsAsync(FinancialReportRequest request, string userId);
}

public class FinancialReportService : BaseReadService<Booking, FinancialReportResponse, FinancialReportRequest>, IFinancialReportService
{
    private readonly ICurrentUserService _currentUserService;

    public FinancialReportService(
        ERentsContext context, 
        IMapper mapper, 
        ILogger<FinancialReportService> logger,
        ICurrentUserService currentUserService) 
        : base(context, mapper, logger)
    {
        _currentUserService = currentUserService;
    }

    public async Task<FinancialReportSummary> GetFinancialReportsAsync(FinancialReportRequest request, string userId)
    {
        // Get user's properties (landlord view)
        var userProperties = await Context.Set<Property>()
            .Where(p => p.Owner.Email == userId)
            .Select(p => p.PropertyId)
            .ToListAsync();

        if (!userProperties.Any())
        {
            return new FinancialReportSummary();
        }

        // Build base query - include Cancelled bookings in addition to Completed/Active
        var query = Context.Set<Booking>().AsNoTracking()
            .Include(b => b.Property)
            .Include(b => b.User)
            .Where(b => userProperties.Contains(b.PropertyId))
            .Where(b => b.StartDate >= DateOnly.FromDateTime(request.StartDate))
            .Where(b => b.StartDate <= DateOnly.FromDateTime(request.EndDate))
            .Where(b => b.Status == BookingStatusEnum.Completed || 
                       b.Status == BookingStatusEnum.Active ||
                       b.Status == BookingStatusEnum.Cancelled);

        // Apply additional filters
        query = AddFilter(query, request);

        // Apply sorting using custom financial report sorting
        FinancialReportSortBy? financialSortBy = null;
        if (!string.IsNullOrEmpty(request.SortBy))
        {
            Enum.TryParse<FinancialReportSortBy>(request.SortBy, out var parsedSortBy);
            financialSortBy = parsedSortBy;
        }
        query = ApplySorting(query, financialSortBy, request.SortDescending);

        // Get total count for pagination
        var totalCount = await query.CountAsync();
        
        // Apply pagination and get booking IDs first
        var paginatedBookingIds = await query
            .Skip((request.Page - 1) * request.PageSize)
            .Take(request.PageSize)
            .Select(b => b.BookingId)
            .ToListAsync();

        // Fetch refund amounts for these bookings from Payment table
        // Note: Refund amounts are stored as negative values, so we use Math.Abs() for display
        var refundsByBooking = await Context.Set<Payment>()
            .AsNoTracking()
            .Where(p => paginatedBookingIds.Contains(p.BookingId ?? 0))
            .Where(p => p.PaymentType == "Refund" && p.PaymentStatus == "Completed")
            .GroupBy(p => p.BookingId)
            .Select(g => new { BookingId = g.Key, RefundAmount = Math.Abs(g.Sum(p => p.Amount)) })
            .ToDictionaryAsync(x => x.BookingId ?? 0, x => x.RefundAmount);

        // Fetch booking details with refund info
        var bookings = await query
            .Where(b => paginatedBookingIds.Contains(b.BookingId))
            .Select(b => new FinancialReportResponse
            {
                BookingId = b.BookingId,
                PropertyName = b.Property.Name,
                TenantName = $"{b.User.FirstName} {b.User.LastName}",
                StartDate = b.StartDate.ToDateTime(TimeOnly.MinValue),
                EndDate = b.EndDate.HasValue ? b.EndDate.Value.ToDateTime(TimeOnly.MinValue) : (DateTime?)null,
                RentalType = b.Property.RentingType,
                TotalPrice = b.TotalPrice,
                Currency = "USD",
                Status = b.Status,
                RefundAmount = 0 // Will be populated below
            })
            .ToListAsync();

        // Apply refund amounts to bookings
        // For cancelled bookings without a Refund payment record, use TotalPrice as refund
        // This handles cases where Stripe was disabled or manual refunds were processed
        foreach (var booking in bookings)
        {
            if (refundsByBooking.TryGetValue(booking.BookingId, out var refundAmount))
            {
                booking.RefundAmount = refundAmount;
            }
            else if (booking.Status == BookingStatusEnum.Cancelled)
            {
                // Cancelled bookings without a Refund payment record are assumed to be fully refunded
                // This ensures cancelled revenue is properly deducted from reports
                booking.RefundAmount = booking.TotalPrice;
            }
        }

        // Apply grouping if requested
        var groupedReports = ApplyGrouping(bookings, request.GroupBy);

        // Calculate summary statistics
        var totalRevenue = bookings.Sum(b => b.TotalPrice);
        var totalRefunds = bookings.Sum(b => b.RefundAmount);
        var netRevenue = totalRevenue - totalRefunds;
        var totalBookings = bookings.Count;
        var totalCancellations = bookings.Count(b => b.Status == BookingStatusEnum.Cancelled);
        var activeBookings = bookings.Where(b => b.Status != BookingStatusEnum.Cancelled).ToList();
        var averageBookingValue = activeBookings.Any() ? activeBookings.Sum(b => b.NetRevenue) / activeBookings.Count : 0;

        // Calculate group totals (using net revenue)
        var groupTotals = new Dictionary<string, decimal>();
        if (request.GroupBy.HasValue && request.GroupBy != FinancialReportGroupBy.None)
        {
            groupTotals = groupedReports
                .Where(r => !string.IsNullOrEmpty(r.GroupKey))
                .GroupBy(r => r.GroupKey!)
                .ToDictionary(g => g.Key, g => g.Sum(r => r.NetRevenue));
        }

        return new FinancialReportSummary
        {
            Reports = groupedReports,
            TotalRevenue = totalRevenue,
            TotalBookings = totalBookings,
            AverageBookingValue = averageBookingValue,
            GroupTotals = groupTotals,
            TotalPages = (int)Math.Ceiling((double)totalCount / request.PageSize),
            CurrentPage = request.Page,
            PageSize = request.PageSize,
            TotalCancellations = totalCancellations,
            TotalRefunds = totalRefunds,
            NetRevenue = netRevenue
        };
    }


    protected override IQueryable<Booking> AddFilter(IQueryable<Booking> query, FinancialReportRequest search)
    {
        // Apply property filter
        if (search.PropertyId.HasValue)
        {
            query = query.Where(b => b.PropertyId == search.PropertyId.Value);
        }

        // Apply rental type filter
        if (search.RentalType.HasValue)
        {
            query = query.Where(b => b.Property.RentingType == search.RentalType.Value);
        }

        // Apply booking status filter
        if (search.BookingStatus.HasValue)
        {
            query = query.Where(b => b.Status == search.BookingStatus.Value);
        }

        return query;
    }

    protected override IQueryable<Booking> AddIncludes(IQueryable<Booking> query)
    {
        return query
            .Include(b => b.Property)
            .Include(b => b.User);
    }

    private static IQueryable<Booking> ApplySorting(IQueryable<Booking> query, FinancialReportSortBy? sortBy, bool descending)
    {
        return sortBy switch
        {
            FinancialReportSortBy.PropertyName => descending 
                ? query.OrderByDescending(b => b.Property.Name)
                : query.OrderBy(b => b.Property.Name),
            FinancialReportSortBy.TenantName => descending
                ? query.OrderByDescending(b => b.User.FirstName).ThenByDescending(b => b.User.LastName)
                : query.OrderBy(b => b.User.FirstName).ThenBy(b => b.User.LastName),
            FinancialReportSortBy.StartDate => descending
                ? query.OrderByDescending(b => b.StartDate)
                : query.OrderBy(b => b.StartDate),
            FinancialReportSortBy.EndDate => descending
                ? query.OrderByDescending(b => b.EndDate)
                : query.OrderBy(b => b.EndDate),
            FinancialReportSortBy.TotalPrice => descending
                ? query.OrderByDescending(b => b.TotalPrice)
                : query.OrderBy(b => b.TotalPrice),
            FinancialReportSortBy.RentalType => descending
                ? query.OrderByDescending(b => b.Property.RentingType)
                : query.OrderBy(b => b.Property.RentingType),
            _ => query.OrderByDescending(b => b.StartDate) // Default sort by start date descending
        };
    }

    private static List<FinancialReportResponse> ApplyGrouping(List<FinancialReportResponse> reports, FinancialReportGroupBy? groupBy)
    {
        if (!groupBy.HasValue || groupBy == FinancialReportGroupBy.None)
        {
            return reports;
        }

        return groupBy switch
        {
            FinancialReportGroupBy.Property => GroupByProperty(reports),
            FinancialReportGroupBy.Month => GroupByMonth(reports),
            FinancialReportGroupBy.RentalType => GroupByRentalType(reports),
            FinancialReportGroupBy.Day => GroupByDay(reports),
            _ => reports
        };
    }

    private static List<FinancialReportResponse> GroupByProperty(List<FinancialReportResponse> reports)
    {
        return reports
            .GroupBy(r => r.PropertyName)
            .SelectMany(g => g.Select(r => new FinancialReportResponse
            {
                BookingId = r.BookingId,
                PropertyName = r.PropertyName,
                TenantName = r.TenantName,
                StartDate = r.StartDate,
                EndDate = r.EndDate,
                RentalType = r.RentalType,
                TotalPrice = r.TotalPrice,
                Currency = r.Currency,
                Status = r.Status,
                GroupKey = g.Key,
                GroupLabel = $"Property: {g.Key}",
                GroupTotal = g.Sum(x => x.TotalPrice),
                GroupCount = g.Count()
            }))
            .OrderBy(r => r.GroupKey)
            .ThenByDescending(r => r.StartDate)
            .ToList();
    }

    private static List<FinancialReportResponse> GroupByMonth(List<FinancialReportResponse> reports)
    {
        return reports
            .GroupBy(r => r.StartDate.ToString("yyyy-MM"))
            .SelectMany(g => g.Select(r => new FinancialReportResponse
            {
                BookingId = r.BookingId,
                PropertyName = r.PropertyName,
                TenantName = r.TenantName,
                StartDate = r.StartDate,
                EndDate = r.EndDate,
                RentalType = r.RentalType,
                TotalPrice = r.TotalPrice,
                Currency = r.Currency,
                Status = r.Status,
                GroupKey = g.Key,
                GroupLabel = $"Month: {DateTime.ParseExact(g.Key, "yyyy-MM", null):MMMM yyyy}",
                GroupTotal = g.Sum(x => x.TotalPrice),
                GroupCount = g.Count()
            }))
            .OrderBy(r => r.GroupKey)
            .ThenByDescending(r => r.StartDate)
            .ToList();
    }

    private static List<FinancialReportResponse> GroupByRentalType(List<FinancialReportResponse> reports)
    {
        return reports
            .GroupBy(r => r.RentalType)
            .SelectMany(g => g.Select(r => new FinancialReportResponse
            {
                BookingId = r.BookingId,
                PropertyName = r.PropertyName,
                TenantName = r.TenantName,
                StartDate = r.StartDate,
                EndDate = r.EndDate,
                RentalType = r.RentalType,
                TotalPrice = r.TotalPrice,
                Currency = r.Currency,
                Status = r.Status,
                GroupKey = g.Key.ToString(),
                GroupLabel = $"Rental Type: {g.Key}",
                GroupTotal = g.Sum(x => x.TotalPrice),
                GroupCount = g.Count()
            }))
            .OrderBy(r => r.GroupKey)
            .ThenByDescending(r => r.StartDate)
            .ToList();
    }

    private static List<FinancialReportResponse> GroupByDay(List<FinancialReportResponse> reports)
    {
        return reports
            .GroupBy(r => r.StartDate.Date)
            .SelectMany(g => g.Select(r => new FinancialReportResponse
            {
                BookingId = r.BookingId,
                PropertyName = r.PropertyName,
                TenantName = r.TenantName,
                StartDate = r.StartDate,
                EndDate = r.EndDate,
                RentalType = r.RentalType,
                TotalPrice = r.TotalPrice,
                Currency = r.Currency,
                Status = r.Status,
                GroupKey = g.Key.ToString("yyyy-MM-dd"),
                GroupLabel = $"Day: {g.Key:dd/MM/yyyy}",
                GroupTotal = g.Sum(x => x.TotalPrice),
                GroupCount = g.Count()
            }))
            .OrderBy(r => r.GroupKey)
            .ThenByDescending(r => r.StartDate)
            .ToList();
    }

}
