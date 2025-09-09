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

        // Build base query using Core BaseReadService functionality
        var query = Context.Set<Booking>().AsNoTracking()
            .Include(b => b.Property)
            .Include(b => b.User)
            .Where(b => userProperties.Contains(b.PropertyId))
            .Where(b => b.StartDate >= DateOnly.FromDateTime(request.StartDate))
            .Where(b => b.StartDate <= DateOnly.FromDateTime(request.EndDate))
            .Where(b => b.Status == BookingStatusEnum.Completed || b.Status == BookingStatusEnum.Active);

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
        
        // Apply pagination
        var bookings = await query
            .Skip((request.Page - 1) * request.PageSize)
            .Take(request.PageSize)
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
                Status = b.Status
            })
            .ToListAsync();

        // Apply grouping if requested
        var groupedReports = ApplyGrouping(bookings, request.GroupBy);

        // Calculate summary statistics
        var totalRevenue = bookings.Sum(b => b.TotalPrice);
        var totalBookings = bookings.Count;
        var averageBookingValue = totalBookings > 0 ? totalRevenue / totalBookings : 0;

        // Calculate group totals
        var groupTotals = new Dictionary<string, decimal>();
        if (request.GroupBy.HasValue && request.GroupBy != FinancialReportGroupBy.None)
        {
            groupTotals = groupedReports
                .Where(r => !string.IsNullOrEmpty(r.GroupKey))
                .GroupBy(r => r.GroupKey!)
                .ToDictionary(g => g.Key, g => g.Sum(r => r.TotalPrice));
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
            PageSize = request.PageSize
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
