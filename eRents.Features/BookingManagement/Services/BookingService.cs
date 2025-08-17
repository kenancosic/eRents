using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using eRents.Domain.Models;
using eRents.Features.BookingManagement.Models;
using AutoMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using eRents.Features.Core;
using eRents.Domain.Shared.Interfaces;

namespace eRents.Features.BookingManagement.Services;

public class BookingService : BaseCrudService<Booking, BookingRequest, BookingResponse, BookingSearch>
{
    public BookingService(
        ERentsContext context,
        IMapper mapper,
        ILogger<BookingService> logger,
        ICurrentUserService? currentUserService = null)
        : base(context, mapper, logger, currentUserService)
    {
    }

    public override async Task<BookingResponse> GetByIdAsync(int id)
    {
        // Fetch with property for ownership validation
        var entity = await Context.Set<Booking>()
            .Include(b => b.Property)
            .FirstOrDefaultAsync(x => x.BookingId == id);

        if (entity == null)
            throw new KeyNotFoundException($"Booking with id {id} not found");

        if (CurrentUser?.IsDesktop == true &&
            !string.IsNullOrWhiteSpace(CurrentUser.UserRole) &&
            (string.Equals(CurrentUser.UserRole, "Owner", StringComparison.OrdinalIgnoreCase) ||
             string.Equals(CurrentUser.UserRole, "Landlord", StringComparison.OrdinalIgnoreCase)))
        {
            var ownerId = CurrentUser.GetUserIdAsInt();
            if (!ownerId.HasValue || entity.Property == null || entity.Property.OwnerId != ownerId.Value)
            {
                throw new KeyNotFoundException($"Booking with id {id} not found");
            }
        }

        return Mapper.Map<BookingResponse>(entity);
    }

    protected override IQueryable<Booking> AddFilter(IQueryable<Booking> query, BookingSearch search)
    {
        if (search.UserId.HasValue)
        {
            query = query.Where(x => x.UserId == search.UserId.Value);
        }

        if (search.PropertyId.HasValue)
        {
            query = query.Where(x => x.PropertyId == search.PropertyId.Value);
        }

        if (search.Status.HasValue)
        {
            query = query.Where(x => x.Status == search.Status.Value);
        }

        if (search.StartDateFrom.HasValue)
        {
            var from = search.StartDateFrom.Value;
            query = query.Where(x => x.StartDate >= from);
        }

        if (search.StartDateTo.HasValue)
        {
            var to = search.StartDateTo.Value;
            query = query.Where(x => x.StartDate <= to);
        }

        if (search.EndDateFrom.HasValue)
        {
            var from = search.EndDateFrom.Value;
            query = query.Where(x => x.EndDate != null && x.EndDate.Value >= from);
        }

        if (search.EndDateTo.HasValue)
        {
            var to = search.EndDateTo.Value;
            query = query.Where(x => x.EndDate != null && x.EndDate.Value <= to);
        }

        if (search.MinTotalPrice.HasValue)
        {
            query = query.Where(x => x.TotalPrice >= search.MinTotalPrice.Value);
        }

        if (search.MaxTotalPrice.HasValue)
        {
            query = query.Where(x => x.TotalPrice <= search.MaxTotalPrice.Value);
        }

        if (!string.IsNullOrWhiteSpace(search.PaymentStatus))
        {
            query = query.Where(x => x.PaymentStatus == search.PaymentStatus);
        }

        if (!string.IsNullOrWhiteSpace(search.City))
        {
            // Filter via owned type Property.Address.City
            query = query.Where(x => x.Property.Address != null && x.Property.Address.City == search.City);
        }

        // Auto-scope for Desktop owners/landlords: only bookings for properties owned by current user
        if (CurrentUser?.IsDesktop == true &&
            !string.IsNullOrWhiteSpace(CurrentUser.UserRole) &&
            (string.Equals(CurrentUser.UserRole, "Owner", StringComparison.OrdinalIgnoreCase) ||
             string.Equals(CurrentUser.UserRole, "Landlord", StringComparison.OrdinalIgnoreCase)))
        {
            var ownerId = CurrentUser.GetUserIdAsInt();
            if (ownerId.HasValue)
            {
                query = query.Where(x => x.Property.OwnerId == ownerId.Value);
            }
        }

        return query;
    }

    protected override IQueryable<Booking> AddSorting(IQueryable<Booking> query, BookingSearch search)
    {
        var sortBy = (search.SortBy ?? string.Empty).Trim().ToLower();
        var sortDir = (search.SortDirection ?? "asc").Trim().ToLower();
        var desc = sortDir == "desc";

        query = sortBy switch
        {
            "startdate" => desc ? query.OrderByDescending(x => x.StartDate) : query.OrderBy(x => x.StartDate),
            "totalprice" => desc ? query.OrderByDescending(x => x.TotalPrice) : query.OrderBy(x => x.TotalPrice),
            "createdat" => desc ? query.OrderByDescending(x => x.CreatedAt) : query.OrderBy(x => x.CreatedAt),
            "updatedat" => desc ? query.OrderByDescending(x => x.UpdatedAt) : query.OrderBy(x => x.UpdatedAt),
            _ => desc ? query.OrderByDescending(x => x.BookingId) : query.OrderBy(x => x.BookingId)
        };

        return query;
    }

    protected override async Task BeforeCreateAsync(Booking entity, BookingRequest request)
    {
        // Optional domain checks (MinimumStayDays)
        if (request.EndDate.HasValue)
        {
            var property = await Context.Set<Property>()
                .AsNoTracking()
                .Where(p => p.PropertyId == request.PropertyId)
                .Select(p => new { p.MinimumStayDays })
                .FirstOrDefaultAsync();

            if (property != null && property.MinimumStayDays.HasValue && property.MinimumStayDays.Value > 0)
            {
                var minEnd = request.StartDate.AddDays(property.MinimumStayDays.Value);
                if (request.EndDate.Value < minEnd)
                {
                    throw new InvalidOperationException($"EndDate must be at least {property.MinimumStayDays.Value} days after StartDate.");
                }
            }
        }
    }

    protected override async Task BeforeUpdateAsync(Booking entity, BookingRequest request)
    {
        if (request.EndDate.HasValue)
        {
            var property = await Context.Set<Property>()
                .AsNoTracking()
                .Where(p => p.PropertyId == request.PropertyId)
                .Select(p => new { p.MinimumStayDays })
                .FirstOrDefaultAsync();

            if (property != null && property.MinimumStayDays.HasValue && property.MinimumStayDays.Value > 0)
            {
                var minEnd = request.StartDate.AddDays(property.MinimumStayDays.Value);
                if (request.EndDate.Value < minEnd)
                {
                    throw new InvalidOperationException($"EndDate must be at least {property.MinimumStayDays.Value} days after StartDate.");
                }
            }
        }
    }
}