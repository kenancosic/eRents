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
using eRents.Features.PaymentManagement.Services;

namespace eRents.Features.BookingManagement.Services;

public class BookingService : BaseCrudService<Booking, BookingRequest, BookingResponse, BookingSearch>
{
    private readonly ISubscriptionService? _subscriptionService;

    public BookingService(
        ERentsContext context,
        IMapper mapper,
        ILogger<BookingService> logger,
        ICurrentUserService? currentUserService = null,
        ISubscriptionService? subscriptionService = null)
        : base(context, mapper, logger, currentUserService)
    {
        _subscriptionService = subscriptionService;
    }

    public override async Task<BookingResponse> CreateAsync(BookingRequest request)
    {
        // First create the booking using the base implementation
        var response = await base.CreateAsync(request);
        
        // Get the created booking entity
        var booking = await Context.Set<Booking>().FindAsync(response.BookingId);
        
        // For monthly rentals, create the actual subscription after booking is created
        if (booking != null && booking.IsSubscription && _subscriptionService != null)
        {
            try
            {
                // Create subscription for monthly rental
                var subscription = await _subscriptionService.CreateSubscriptionAsync(
                    booking.UserId, // tenantId (using userId for now, might need to create actual tenant record)
                    booking.PropertyId,
                    booking.BookingId,
                    booking.TotalPrice, // monthly amount
                    booking.StartDate,
                    booking.EndDate);

                // Update booking with subscription reference
                booking.SubscriptionId = subscription.SubscriptionId;
                await Context.SaveChangesAsync();
            }
            catch (Exception ex)
            {
                Logger.LogError(ex, "Failed to create subscription for booking {BookingId}", booking.BookingId);
                // Don't throw here as we still want to complete the booking
            }
        }
        
        return response;
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
        query = query.Include(b => b.User).Include(b => b.Property);
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

        if (!string.IsNullOrWhiteSpace(search.RentingType))
        {
            // Filter via owned type Property.RentingType
            query = query.Where(x => x.Property.RentingType.ToString() == search.RentingType);
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

        // Prevent creating a booking that overlaps an active tenancy for the same property
        var bookingStart = request.StartDate;
        var bookingEnd = request.EndDate ?? request.StartDate; // treat 1-day stay when EndDate is null

        var hasActiveTenantOverlap = await Context.Set<Tenant>()
            .AsNoTracking()
            .Where(t => t.PropertyId == request.PropertyId)
            .Where(t => t.LeaseStartDate.HasValue)
            .Where(t => t.LeaseStartDate!.Value <= bookingEnd)
            .Where(t => !t.LeaseEndDate.HasValue || t.LeaseEndDate!.Value >= bookingStart)
            .AnyAsync();

        if (hasActiveTenantOverlap)
        {
            throw new InvalidOperationException("Cannot create booking: property has an active tenancy overlapping the requested dates.");
        }

        // For monthly rentals, create a subscription if the property is set to monthly renting type
        var bookingProperty = await Context.Set<Property>()
            .AsNoTracking()
            .FirstOrDefaultAsync(p => p.PropertyId == request.PropertyId);

        if (bookingProperty != null && bookingProperty.RentingType == Domain.Models.Enums.RentalType.Monthly && 
            _subscriptionService != null)
        {
            // This is a monthly rental, mark the booking as a subscription
            entity.IsSubscription = true;
        }
    }

    public async Task<BookingResponse> CancelBooking(int bookingId)
    {
        var entity = await Context.Set<Booking>()
            .Include(b => b.Property)
            .FirstOrDefaultAsync(x => x.BookingId == bookingId);

        if (entity == null)
            throw new KeyNotFoundException($"Booking with id {bookingId} not found");

        if (CurrentUser?.IsDesktop == true &&
            !string.IsNullOrWhiteSpace(CurrentUser.UserRole) &&
            (string.Equals(CurrentUser.UserRole, "Owner", StringComparison.OrdinalIgnoreCase) ||
             string.Equals(CurrentUser.UserRole, "Landlord", StringComparison.OrdinalIgnoreCase)))
        {
            var ownerId = CurrentUser.GetUserIdAsInt();
            if (!ownerId.HasValue || entity.Property == null || entity.Property.OwnerId != ownerId.Value)
            {
                throw new KeyNotFoundException($"Booking with id {bookingId} not found");
            }
        }

        entity.Status = Domain.Models.Enums.BookingStatusEnum.Cancelled;
        await Context.SaveChangesAsync();
        return Mapper.Map<BookingResponse>(entity);
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

        // Prevent updating a booking into a period that overlaps an active tenancy for the same property
        var bookingStart = request.StartDate;
        var bookingEnd = request.EndDate ?? request.StartDate;

        var hasActiveTenantOverlap = await Context.Set<Tenant>()
            .AsNoTracking()
            .Where(t => t.PropertyId == request.PropertyId)
            .Where(t => t.LeaseStartDate.HasValue)
            .Where(t => t.LeaseStartDate!.Value <= bookingEnd)
            .Where(t => !t.LeaseEndDate.HasValue || t.LeaseEndDate!.Value >= bookingStart)
            .AnyAsync();

        if (hasActiveTenantOverlap)
        {
            throw new InvalidOperationException("Cannot update booking: property has an active tenancy overlapping the requested dates.");
        }
    }

}