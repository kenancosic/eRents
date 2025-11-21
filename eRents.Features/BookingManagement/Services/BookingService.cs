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
using eRents.Features.Shared.Services;

namespace eRents.Features.BookingManagement.Services;

public class BookingService : BaseCrudService<Booking, BookingRequest, BookingResponse, BookingSearch>
{
    private readonly ISubscriptionService? _subscriptionService;
    private readonly INotificationService? _notificationService;

    public BookingService(
        ERentsContext context,
        IMapper mapper,
        ILogger<BookingService> logger,
        ICurrentUserService? currentUserService = null,
        ISubscriptionService? subscriptionService = null,
        INotificationService? notificationService = null)
        : base(context, mapper, logger, currentUserService)
    {
        _subscriptionService = subscriptionService;
        _notificationService = notificationService;
    }

    public async Task<BookingResponse> ExtendBookingAsync(int bookingId, BookingExtensionRequest request)
    {
        // Restrict direct extension to desktop landlord/owner contexts
        if (CurrentUser?.IsDesktop != true)
        {
            throw new InvalidOperationException("Only landlords can extend bookings directly. Tenants should submit an extension request.");
        }

        // Load booking with related property and subscription
        var entity = await Context.Set<Booking>()
            .Include(b => b.Property)
            .Include(b => b.Subscription)
            .FirstOrDefaultAsync(x => x.BookingId == bookingId);

        if (entity == null)
            throw new KeyNotFoundException($"Booking with id {bookingId} not found");

        // Ownership scope for desktop landlords/owners
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

        // Note: ExtendBooking is restricted to desktop landlords earlier; no mobile/tenant scope needed here

        // Only allow extensions for monthly rentals that are subscription based
        if (entity.Property == null || entity.Property.RentingType != Domain.Models.Enums.RentalType.Monthly || !entity.IsSubscription)
        {
            throw new InvalidOperationException("Only monthly subscription-based bookings can be extended.");
        }

        // Determine target end date
        DateOnly currentEnd = entity.EndDate ?? entity.StartDate;
        DateOnly? targetEnd = request.NewEndDate;
        if (!targetEnd.HasValue && request.ExtendByMonths.HasValue)
        {
            targetEnd = currentEnd.AddMonths(request.ExtendByMonths.Value);
        }

        if (!targetEnd.HasValue)
        {
            throw new InvalidOperationException("Provide either NewEndDate or ExtendByMonths.");
        }

        // Validate target end is not earlier than current end
        if (entity.EndDate.HasValue && targetEnd.Value < entity.EndDate.Value)
        {
            throw new InvalidOperationException("New end date must be later than or equal to the current end date.");
        }

        // Respect MinimumStayDays if defined
        var propertyInfo = await Context.Set<Property>()
            .AsNoTracking()
            .Where(p => p.PropertyId == entity.PropertyId)
            .Select(p => new { p.MinimumStayDays })
            .FirstOrDefaultAsync();

        if (propertyInfo != null && propertyInfo.MinimumStayDays.HasValue && propertyInfo.MinimumStayDays.Value > 0)
        {
            var minEnd = entity.StartDate.AddDays(propertyInfo.MinimumStayDays.Value);
            if (targetEnd.Value < minEnd)
            {
                throw new InvalidOperationException($"EndDate must be at least {propertyInfo.MinimumStayDays.Value} days after StartDate.");
            }
        }

        // Overlap protection with active tenancies (reuse logic as in BeforeUpdateAsync)
        var bookingStart = entity.StartDate;
        var bookingEnd = targetEnd.Value;

        var hasActiveTenantOverlap = await Context.Set<Tenant>()
            .AsNoTracking()
            .Where(t => t.PropertyId == entity.PropertyId)
            .Where(t => t.LeaseStartDate.HasValue)
            .Where(t => t.LeaseStartDate!.Value <= bookingEnd)
            .Where(t => !t.LeaseEndDate.HasValue || t.LeaseEndDate!.Value >= bookingStart)
            .AnyAsync();

        if (hasActiveTenantOverlap)
        {
            throw new InvalidOperationException("Cannot extend booking: property has an active tenancy overlapping the requested dates.");
        }

        // Apply updates
        entity.EndDate = targetEnd;

        if (entity.Subscription != null)
        {
            entity.Subscription.EndDate = targetEnd;
            if (request.NewMonthlyAmount.HasValue)
            {
                entity.Subscription.MonthlyAmount = request.NewMonthlyAmount.Value;
            }

            // Update subscription status if next payment is beyond new end
            if (entity.Subscription.EndDate.HasValue && entity.Subscription.NextPaymentDate > entity.Subscription.EndDate.Value)
            {
                entity.Subscription.Status = Domain.Models.Enums.SubscriptionStatusEnum.Completed;
            }
            else if (entity.Subscription.Status == Domain.Models.Enums.SubscriptionStatusEnum.Completed)
            {
                // Re-activate if previously completed and now extended beyond next payment
                entity.Subscription.Status = Domain.Models.Enums.SubscriptionStatusEnum.Active;
            }
        }

        await Context.SaveChangesAsync();

        return Mapper.Map<BookingResponse>(entity);
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
                // Ensure a Tenant exists for this user/property pair
                var tenant = await Context.Set<Tenant>()
                    .FirstOrDefaultAsync(t => t.UserId == booking.UserId && t.PropertyId == booking.PropertyId);

                if (tenant == null)
                {
                    tenant = new Tenant
                    {
                        UserId = booking.UserId,
                        PropertyId = booking.PropertyId,
                        LeaseStartDate = booking.StartDate,
                        LeaseEndDate = booking.EndDate,
                        TenantStatus = eRents.Domain.Models.Enums.TenantStatusEnum.Active
                    };
                    Context.Set<Tenant>().Add(tenant);
                    await Context.SaveChangesAsync(); // obtain TenantId
                }

                // Create subscription for monthly rental using the TenantId
                var subscription = await _subscriptionService.CreateSubscriptionAsync(
                    tenant.TenantId,
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

        // Auto-scope for Mobile clients: ensure non-desktop callers see only their own bookings
        // Frontend also passes UserId explicitly now, but this enforces correctness even if omitted.
        if (CurrentUser?.IsDesktop != true)
        {
            var currentUserId = CurrentUser?.GetUserIdAsInt();
            if (currentUserId.HasValue)
            {
                query = query.Where(x => x.UserId == currentUserId.Value);
            }
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
        // Infer UserId from authenticated user if not provided by client
        if ((entity.UserId == 0 || entity.UserId == default) && CurrentUser != null)
        {
            var currentUserId = CurrentUser.GetUserIdAsInt();
            if (currentUserId.HasValue)
            {
                entity.UserId = currentUserId.Value;
            }
        }

        // Mobile-only restriction: owners cannot book their own properties via mobile client
        if (CurrentUser?.IsDesktop != true)
        {
            var currentUserId = CurrentUser?.GetUserIdAsInt();
            if (currentUserId.HasValue)
            {
                var ownerInfo = await Context.Set<Property>()
                    .AsNoTracking()
                    .Where(p => p.PropertyId == request.PropertyId)
                    .Select(p => new { p.OwnerId })
                    .FirstOrDefaultAsync();

                if (ownerInfo != null && ownerInfo.OwnerId == currentUserId.Value)
                {
                    throw new InvalidOperationException("Owners cannot book their own properties.");
                }
            }
        }

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

    public async Task<BookingResponse> CancelBooking(int bookingId, CancelBookingRequest? request)
    {
        var entity = await Context.Set<Booking>()
            .Include(b => b.Property)
            .Include(b => b.Subscription)
            .FirstOrDefaultAsync(x => x.BookingId == bookingId);

        if (entity == null)
            throw new KeyNotFoundException($"Booking with id {bookingId} not found");

        // Ownership scope for desktop landlords/owners
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

        // Mobile/tenant scope: only the booking owner can cancel on non-desktop clients
        if (CurrentUser?.IsDesktop != true)
        {
            var currentUserId = CurrentUser?.GetUserIdAsInt();
            if (!currentUserId.HasValue || entity.UserId != currentUserId.Value)
            {
                throw new KeyNotFoundException($"Booking with id {bookingId} not found");
            }
        }

        var today = DateOnly.FromDateTime(DateTime.UtcNow);

        // Daily rentals: refund if cancelled at least 3 days before start
        if (entity.Property.RentingType == Domain.Models.Enums.RentalType.Daily)
        {
            var eligibleForRefund = today <= entity.StartDate.AddDays(-3);
            
            // TODO: Implement Stripe refund processing through Stripe API
            // For now, manual refund processing is required
            if (eligibleForRefund)
            {
                Logger.LogInformation(
                    "Booking {BookingId} is eligible for refund. Manual Stripe refund processing required for payment {PaymentRef}",
                    bookingId, entity.PaymentReference);
            }

            entity.Status = Domain.Models.Enums.BookingStatusEnum.Cancelled;
            entity.UpdatedAt = DateTime.UtcNow;
            await Context.SaveChangesAsync();
            return Mapper.Map<BookingResponse>(entity);
        }

        // Monthly rentals
        if (today < entity.StartDate)
        {
            // Before stay commences: free cancellation
            if (entity.SubscriptionId.HasValue && _subscriptionService != null)
            {
                try { await _subscriptionService.CancelSubscriptionAsync(entity.SubscriptionId.Value); }
                catch (Exception ex) { Logger.LogError(ex, "Failed to cancel subscription for booking {BookingId}", bookingId); }
            }

            entity.Status = Domain.Models.Enums.BookingStatusEnum.Cancelled;
            entity.UpdatedAt = DateTime.UtcNow;
            await Context.SaveChangesAsync();
            return Mapper.Map<BookingResponse>(entity);
        }
        else
        {
            // In-stay: adjust contract end; require cancellation date
            var cancelDate = request?.CancellationDate ?? today;
            if (entity.EndDate.HasValue && cancelDate > entity.EndDate.Value)
            {
                throw new InvalidOperationException("Cancellation date cannot be after current contract end date.");
            }
            if (cancelDate < today) cancelDate = today;

            // Update booking end date (contract)
            entity.EndDate = cancelDate;
            entity.UpdatedAt = DateTime.UtcNow;

            // Ensure one additional month charge by extending subscription end date minimally by one month
            if (entity.Subscription != null)
            {
                var extraEnd = cancelDate.AddMonths(1);
                if (entity.Subscription.EndDate.HasValue)
                {
                    // Do not extend beyond existing contract
                    var currentEnd = entity.Subscription.EndDate.Value;
                    entity.Subscription.EndDate = extraEnd <= currentEnd ? extraEnd : currentEnd;
                }
                else
                {
                    entity.Subscription.EndDate = extraEnd;
                }
            }

            await Context.SaveChangesAsync();
            return Mapper.Map<BookingResponse>(entity);
        }
    }

    public async Task<BookingResponse> ApproveBookingAsync(int bookingId)
    {
        // Only landlords/owners from desktop can approve
        if (CurrentUser?.IsDesktop == true &&
            !string.IsNullOrWhiteSpace(CurrentUser.UserRole) &&
            !(string.Equals(CurrentUser.UserRole, "Owner", StringComparison.OrdinalIgnoreCase) ||
              string.Equals(CurrentUser.UserRole, "Landlord", StringComparison.OrdinalIgnoreCase)))
        {
            throw new InvalidOperationException("Only landlords can approve bookings.");
        }

        var entity = await Context.Set<Booking>()
            .Include(b => b.Property)
            .FirstOrDefaultAsync(x => x.BookingId == bookingId);

        if (entity == null)
            throw new KeyNotFoundException($"Booking with id {bookingId} not found");

        // If desktop landlord, ensure ownership
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

        // Set status to Upcoming on approval (frontend treats Upcoming monthly bookings as accepted/pending start)
        entity.Status = Domain.Models.Enums.BookingStatusEnum.Upcoming;
        await Context.SaveChangesAsync();

        // Notify tenant if service is available
        if (_notificationService != null)
        {
            try
            {
                await _notificationService.CreateBookingNotificationAsync(
                    entity.UserId,
                    entity.BookingId,
                    "Lease Accepted",
                    "Your lease application was accepted by the landlord.");
            }
            catch (Exception ex)
            {
                Logger.LogError(ex, "Failed to send approval notification for booking {BookingId}", bookingId);
            }
        }

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