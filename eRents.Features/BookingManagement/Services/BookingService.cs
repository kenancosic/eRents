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
using eRents.Features.PaymentManagement.Interfaces;
using eRents.Features.PaymentManagement.Services;
using eRents.Features.Shared.Services;

namespace eRents.Features.BookingManagement.Services;

public class BookingService : BaseCrudService<Booking, BookingRequest, BookingResponse, BookingSearch>
{
    private readonly ISubscriptionService? _subscriptionService;
    private readonly INotificationService? _notificationService;
    private readonly IStripePaymentService? _stripePaymentService;

    public BookingService(
        ERentsContext context,
        IMapper mapper,
        ILogger<BookingService> logger,
        ICurrentUserService? currentUserService = null,
        ISubscriptionService? subscriptionService = null,
        INotificationService? notificationService = null,
        IStripePaymentService? stripePaymentService = null)
        : base(context, mapper, logger, currentUserService)
    {
        _subscriptionService = subscriptionService;
        _notificationService = notificationService;
        _stripePaymentService = stripePaymentService;
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

        // Overlap protection with active tenancies (exclude the current tenant's own tenancy)
        var bookingStart = entity.StartDate;
        var bookingEnd = targetEnd.Value;

        var hasActiveTenantOverlap = await Context.Set<Tenant>()
            .AsNoTracking()
            .Where(t => t.PropertyId == entity.PropertyId)
            .Where(t => t.UserId != entity.UserId) // Exclude the current booking's tenant
            .Where(t => t.LeaseStartDate.HasValue)
            .Where(t => t.LeaseStartDate!.Value < bookingEnd)
            .Where(t => !t.LeaseEndDate.HasValue || t.LeaseEndDate!.Value > bookingStart)
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
        
        // Get the created booking entity with property info
        var booking = await Context.Set<Booking>()
            .Include(b => b.Property)
            .FirstOrDefaultAsync(b => b.BookingId == response.BookingId);
        
        // Business rule: Daily rentals are auto-approved after payment, never require landlord approval
        // Only monthly (subscription) rentals require landlord approval and get Pending status
        if (booking != null)
        {
            if (booking.IsSubscription)
            {
                // Monthly rental: set status to Pending (requires landlord approval)
                // Tenant and Subscription will be created upon approval
                booking.Status = Domain.Models.Enums.BookingStatusEnum.Pending;
                await Context.SaveChangesAsync();
                
                // Update response to reflect the Pending status
                response = Mapper.Map<BookingResponse>(booking);
            }
            else if (booking.Property?.RentingType == Domain.Models.Enums.RentalType.Daily)
            {
                // Daily rental: ensure status is Upcoming (auto-approved), never Pending
                // This is a safeguard to enforce the business rule
                var today = DateOnly.FromDateTime(DateTime.UtcNow);
                var correctStatus = today >= booking.StartDate 
                    ? Domain.Models.Enums.BookingStatusEnum.Active 
                    : Domain.Models.Enums.BookingStatusEnum.Upcoming;
                
                if (booking.Status == Domain.Models.Enums.BookingStatusEnum.Pending)
                {
                    booking.Status = correctStatus;
                    await Context.SaveChangesAsync();
                    response = Mapper.Map<BookingResponse>(booking);
                    Logger.LogInformation("Daily rental booking {BookingId} auto-corrected from Pending to {Status}", 
                        booking.BookingId, correctStatus);
                }
            }
        }

        // Send booking creation notifications
        if (booking != null && _notificationService != null)
        {
            try
            {
                var propertyName = booking.Property?.Name ?? "property";
                var startDate = booking.StartDate.ToString("MMM dd, yyyy");
                var isMonthly = booking.IsSubscription;

                // Notify tenant of booking creation
                await _notificationService.CreateBookingNotificationAsync(
                    booking.UserId,
                    booking.BookingId,
                    isMonthly ? "Application Submitted" : "Booking Confirmed",
                    isMonthly 
                        ? $"Your rental application for {propertyName} starting {startDate} has been submitted. You will be notified once the landlord reviews your application."
                        : $"Your booking for {propertyName} on {startDate} has been created. Complete payment to confirm.");

                // Notify landlord of new booking
                if (booking.Property != null)
                {
                    await _notificationService.CreateBookingNotificationAsync(
                        booking.Property.OwnerId,
                        booking.BookingId,
                        isMonthly ? "New Rental Application" : "New Booking Request",
                        isMonthly
                            ? $"New rental application received for {propertyName} starting {startDate}. Review and approve in your dashboard."
                            : $"New booking for {propertyName} on {startDate}. Payment pending.");
                }
            }
            catch (Exception notifyEx)
            {
                Logger.LogError(notifyEx, "Failed to send booking creation notifications for booking {BookingId}", booking.BookingId);
                // Don't throw - notifications shouldn't break booking creation
            }
        }
        
        return response;
    }

    public override async Task<BookingResponse> GetByIdAsync(int id)
    {
        // Fetch with property for ownership validation and subscription for monthly amount
        var entity = await Context.Set<Booking>()
            .Include(b => b.Property)
            .Include(b => b.Subscription)
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
        query = query.Include(b => b.User).Include(b => b.Property).ThenInclude(p => p.Images).Include(b => b.Subscription);
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

        // Auto-scope for Desktop clients
        // Desktop app is for landlords/owners only - enforce ownership filtering
        if (CurrentUser?.IsDesktop == true)
        {
            var userRole = CurrentUser.UserRole ?? string.Empty;
            var isOwnerOrLandlord = string.Equals(userRole, "Owner", StringComparison.OrdinalIgnoreCase) ||
                                    string.Equals(userRole, "Landlord", StringComparison.OrdinalIgnoreCase);
            
            if (isOwnerOrLandlord)
            {
                // Owners/Landlords see only bookings for their properties
                var ownerId = CurrentUser.GetUserIdAsInt();
                if (ownerId.HasValue)
                {
                    query = query.Where(x => x.Property.OwnerId == ownerId.Value);
                }
            }
            else
            {
                // Non-owner desktop users should not access booking management
                query = query.Where(x => false);
                Logger.LogWarning("Non-owner user {UserId} attempted to access booking management from desktop", 
                    CurrentUser.GetUserIdAsInt());
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
        var bookingEnd = request.EndDate ?? request.StartDate;

        var hasActiveTenantOverlap = await Context.Set<Tenant>()
            .AsNoTracking()
            .Where(t => t.PropertyId == request.PropertyId)
            .Where(t => t.LeaseStartDate.HasValue)
            .Where(t => t.LeaseStartDate!.Value < bookingEnd)
            .Where(t => !t.LeaseEndDate.HasValue || t.LeaseEndDate!.Value > bookingStart)
            .AnyAsync();

        if (hasActiveTenantOverlap)
        {
            throw new InvalidOperationException("Cannot create booking: property has an active tenancy overlapping the requested dates.");
        }

        // Prevent same user from having multiple non-cancelled bookings on the same property
        // This catches cases where Tenant record doesn't exist yet (pending approval) or for daily rentals
        // Only check Confirmed/Upcoming bookings (not Pending or Cancelled)
        var hasExistingActiveBooking = await Context.Set<Booking>()
            .AsNoTracking()
            .Where(b => b.PropertyId == request.PropertyId)
            .Where(b => b.UserId == entity.UserId)
            .Where(b => b.Status == Domain.Models.Enums.BookingStatusEnum.Approved || b.Status == Domain.Models.Enums.BookingStatusEnum.Upcoming)
            // Check for date overlap using strict inequality to allow adjacent bookings
            .Where(b => b.StartDate < bookingEnd)
            .Where(b => !b.EndDate.HasValue || b.EndDate.Value > bookingStart)
            .AnyAsync();

        if (hasExistingActiveBooking)
        {
            throw new InvalidOperationException("You already have an active or upcoming booking for this property during this period.");
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
            .Include(b => b.User)
            .FirstOrDefaultAsync(x => x.BookingId == bookingId);

        if (entity == null)
            throw new KeyNotFoundException($"Booking with id {bookingId} not found");

        // Determine who is initiating the cancellation
        bool isTenantInitiated = false;
        bool isLandlordInitiated = false;

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
            isLandlordInitiated = true;
        }

        // Mobile/tenant scope: only the booking owner can cancel on non-desktop clients
        if (CurrentUser?.IsDesktop != true)
        {
            var currentUserId = CurrentUser?.GetUserIdAsInt();
            if (!currentUserId.HasValue || entity.UserId != currentUserId.Value)
            {
                throw new KeyNotFoundException($"Booking with id {bookingId} not found");
            }
            isTenantInitiated = true;
        }

        var today = DateOnly.FromDateTime(DateTime.UtcNow);

        // Daily rentals: refund if cancelled at least 3 days before start
        if (entity.Property.RentingType == Domain.Models.Enums.RentalType.Daily)
        {
            var eligibleForRefund = today <= entity.StartDate.AddDays(-3);
            
            // Process Stripe refund if eligible and payment exists
            if (eligibleForRefund && _stripePaymentService != null)
            {
                // Find the completed payment for this booking
                var payment = await Context.Set<Domain.Models.Payment>()
                    .AsNoTracking()
                    .Where(p => p.BookingId == bookingId && p.PaymentStatus == "Completed" && p.PaymentType != "Refund")
                    .FirstOrDefaultAsync();

                if (payment != null)
                {
                    try
                    {
                        var refundResult = await _stripePaymentService.ProcessRefundAsync(
                            payment.PaymentId, 
                            amount: null, // Full refund
                            reason: "requested_by_customer");
                        
                        if (!string.IsNullOrEmpty(refundResult.ErrorMessage))
                        {
                            Logger.LogWarning(
                                "Refund processing failed for booking {BookingId}: {Error}. Manual refund may be required.",
                                bookingId, refundResult.ErrorMessage);
                        }
                        else
                        {
                            Logger.LogInformation(
                                "Refund {RefundId} processed for booking {BookingId}, amount: {Amount}",
                                refundResult.RefundId, bookingId, refundResult.Amount);
                        }
                    }
                    catch (Exception refundEx)
                    {
                        Logger.LogError(refundEx, 
                            "Failed to process refund for booking {BookingId}. Manual refund required.", bookingId);
                    }
                }
                else
                {
                    Logger.LogInformation(
                        "Booking {BookingId} is eligible for refund but no completed payment found.",
                        bookingId);
                }
            }
            else if (eligibleForRefund)
            {
                Logger.LogInformation(
                    "Booking {BookingId} is eligible for refund but Stripe service unavailable. Manual processing required.",
                    bookingId);
            }

            entity.Status = Domain.Models.Enums.BookingStatusEnum.Cancelled;
            entity.UpdatedAt = DateTime.UtcNow;
            await Context.SaveChangesAsync();

            // Send cancellation notification with initiator info
            await SendCancellationNotificationAsync(entity, eligibleForRefund, request?.Reason, 
                isTenantInitiated: isTenantInitiated, isLandlordInitiated: isLandlordInitiated);

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

            // Update the Tenant entity for before-stay cancellation
            var tenantBeforeStart = await Context.Set<Tenant>()
                .FirstOrDefaultAsync(t => t.UserId == entity.UserId && t.PropertyId == entity.PropertyId);
            if (tenantBeforeStart != null)
            {
                tenantBeforeStart.TenantStatus = Domain.Models.Enums.TenantStatusEnum.LeaseEnded;
            }

            // Update property status back to Available
            if (entity.Property != null)
            {
                entity.Property.Status = Domain.Models.Enums.PropertyStatusEnum.Available;
            }

            await Context.SaveChangesAsync();

            // Send cancellation notification (eligible for refund since before start)
            await SendCancellationNotificationAsync(entity, eligibleForRefund: true, request?.Reason,
                isTenantInitiated: isTenantInitiated, isLandlordInitiated: isLandlordInitiated);

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

            // Update booking end date (contract) and set status to Cancelled
            entity.EndDate = cancelDate;
            entity.Status = Domain.Models.Enums.BookingStatusEnum.Cancelled;
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
                
                // Cancel the subscription as well
                entity.Subscription.Status = Domain.Models.Enums.SubscriptionStatusEnum.Cancelled;
            }

            // Auto-cancel any pending lease extension requests for this booking
            var pendingExtensions = await Context.Set<Domain.Models.LeaseExtensionRequest>()
                .Where(e => e.BookingId == bookingId && e.Status == Domain.Models.Enums.LeaseExtensionStatusEnum.Pending)
                .ToListAsync();
            foreach (var ext in pendingExtensions)
            {
                ext.Status = Domain.Models.Enums.LeaseExtensionStatusEnum.Cancelled;
                ext.RespondedAt = DateTime.UtcNow;
            }

            // Update the Tenant entity to reflect lease termination
            var tenant = await Context.Set<Tenant>()
                .FirstOrDefaultAsync(t => t.UserId == entity.UserId && t.PropertyId == entity.PropertyId);
            if (tenant != null)
            {
                tenant.TenantStatus = Domain.Models.Enums.TenantStatusEnum.LeaseEnded;
                tenant.LeaseEndDate = cancelDate;
            }

            // Update property status back to Available
            if (entity.Property != null)
            {
                entity.Property.Status = Domain.Models.Enums.PropertyStatusEnum.Available;
            }

            await Context.SaveChangesAsync();

            // Send lease termination notification (no refund for in-stay termination, charges extra month)
            await SendCancellationNotificationAsync(entity, eligibleForRefund: false, request?.Reason, 
                isEarlyTermination: true, newEndDate: cancelDate,
                isTenantInitiated: isTenantInitiated, isLandlordInitiated: isLandlordInitiated);

            return Mapper.Map<BookingResponse>(entity);
        }
    }

    private async Task SendCancellationNotificationAsync(
        Booking booking, 
        bool eligibleForRefund, 
        string? reason, 
        bool isEarlyTermination = false, 
        DateOnly? newEndDate = null,
        bool isTenantInitiated = false,
        bool isLandlordInitiated = false)
    {
        if (_notificationService == null) return;

        try
        {
            var propertyName = booking.Property?.Name ?? "your property";
            var tenantName = booking.User != null 
                ? $"{booking.User.FirstName} {booking.User.LastName}".Trim() 
                : "Tenant";

            // === TENANT NOTIFICATION ===
            if (booking.User != null)
            {
                var tenantMessageBuilder = new System.Text.StringBuilder();
                
                if (isEarlyTermination)
                {
                    if (isTenantInitiated)
                    {
                        tenantMessageBuilder.AppendLine($"You have requested early termination of your lease for {propertyName}.");
                    }
                    else
                    {
                        tenantMessageBuilder.AppendLine($"Your lease for {propertyName} has been terminated early by the landlord.");
                    }
                    
                    if (newEndDate.HasValue)
                    {
                        tenantMessageBuilder.AppendLine($"New lease end date: {newEndDate.Value:MMMM dd, yyyy}");
                    }
                    tenantMessageBuilder.AppendLine();
                    tenantMessageBuilder.AppendLine("As per the lease agreement, you will be charged for one additional month.");
                }
                else
                {
                    if (isTenantInitiated)
                    {
                        tenantMessageBuilder.AppendLine($"You have cancelled your booking for {propertyName}.");
                    }
                    else
                    {
                        tenantMessageBuilder.AppendLine($"Your booking for {propertyName} has been cancelled by the landlord.");
                    }
                    
                    if (eligibleForRefund)
                    {
                        tenantMessageBuilder.AppendLine();
                        tenantMessageBuilder.AppendLine("You are eligible for a refund. The refund will be processed within 5-7 business days.");
                    }
                }

                if (!string.IsNullOrEmpty(reason))
                {
                    tenantMessageBuilder.AppendLine();
                    tenantMessageBuilder.AppendLine($"Reason: {reason}");
                }

                tenantMessageBuilder.AppendLine();
                tenantMessageBuilder.AppendLine("If you have any questions, please contact your landlord or our support team.");

                await _notificationService.CreateNotificationWithEmailAsync(
                    booking.UserId,
                    isEarlyTermination ? "Lease Termination Notice" : "Booking Cancellation",
                    tenantMessageBuilder.ToString(),
                    "booking_cancellation",
                    sendEmail: true,
                    referenceId: booking.BookingId
                );

                Logger.LogInformation("Sent cancellation notification to tenant {UserId} for booking {BookingId}", 
                    booking.UserId, booking.BookingId);
            }

            // === LANDLORD NOTIFICATION ===
            if (booking.Property?.OwnerId != null && booking.Property.OwnerId > 0)
            {
                var landlordMessageBuilder = new System.Text.StringBuilder();
                
                if (isEarlyTermination)
                {
                    if (isTenantInitiated)
                    {
                        landlordMessageBuilder.AppendLine($"Tenant {tenantName} has requested early termination of their lease for {propertyName}.");
                    }
                    else
                    {
                        landlordMessageBuilder.AppendLine($"You have terminated the lease for {propertyName} (Tenant: {tenantName}).");
                    }
                    
                    if (newEndDate.HasValue)
                    {
                        landlordMessageBuilder.AppendLine($"New lease end date: {newEndDate.Value:MMMM dd, yyyy}");
                    }
                    landlordMessageBuilder.AppendLine();
                    landlordMessageBuilder.AppendLine("The tenant will be charged for one additional month as per the lease agreement.");
                }
                else
                {
                    if (isTenantInitiated)
                    {
                        landlordMessageBuilder.AppendLine($"Tenant {tenantName} has cancelled their booking for {propertyName}.");
                    }
                    else
                    {
                        landlordMessageBuilder.AppendLine($"You have cancelled the booking for {propertyName} (Tenant: {tenantName}).");
                    }
                    
                    if (eligibleForRefund)
                    {
                        landlordMessageBuilder.AppendLine();
                        landlordMessageBuilder.AppendLine("The tenant is eligible for a refund which will be processed within 5-7 business days.");
                    }
                }

                if (!string.IsNullOrEmpty(reason))
                {
                    landlordMessageBuilder.AppendLine();
                    landlordMessageBuilder.AppendLine($"Reason provided: {reason}");
                }

                landlordMessageBuilder.AppendLine();
                landlordMessageBuilder.AppendLine($"Booking dates: {booking.StartDate:MMM dd, yyyy} - {booking.EndDate?.ToString("MMM dd, yyyy") ?? "Open"}");

                await _notificationService.CreateNotificationWithEmailAsync(
                    booking.Property.OwnerId,
                    isEarlyTermination ? "Lease Termination Notice" : "Booking Cancellation Notice",
                    landlordMessageBuilder.ToString(),
                    "booking_cancellation",
                    sendEmail: true,
                    referenceId: booking.BookingId
                );

                Logger.LogInformation("Sent cancellation notification to landlord {OwnerId} for booking {BookingId}", 
                    booking.Property.OwnerId, booking.BookingId);
            }
        }
        catch (Exception ex)
        {
            Logger.LogError(ex, "Failed to send cancellation notifications for booking {BookingId}", booking.BookingId);
        }
    }

    public async Task<BookingResponse> ApproveBookingAsync(int bookingId)
    {
        // Only landlords/owners from desktop can approve
        if (CurrentUser?.IsDesktop != true)
        {
            throw new InvalidOperationException("Only landlords can approve bookings.");
        }

        if (!string.IsNullOrWhiteSpace(CurrentUser.UserRole) &&
            !(string.Equals(CurrentUser.UserRole, "Owner", StringComparison.OrdinalIgnoreCase) ||
              string.Equals(CurrentUser.UserRole, "Landlord", StringComparison.OrdinalIgnoreCase)))
        {
            throw new InvalidOperationException("Only landlords can approve bookings.");
        }

        var entity = await Context.Set<Booking>()
            .Include(b => b.Property)
            .Include(b => b.User)
            .FirstOrDefaultAsync(x => x.BookingId == bookingId);

        if (entity == null)
            throw new KeyNotFoundException($"Booking with id {bookingId} not found");

        // Ensure ownership
        var ownerId = CurrentUser.GetUserIdAsInt();
        if (!ownerId.HasValue || entity.Property == null || entity.Property.OwnerId != ownerId.Value)
        {
            throw new KeyNotFoundException($"Booking with id {bookingId} not found");
        }

        // Only pending bookings can be approved
        if (entity.Status != Domain.Models.Enums.BookingStatusEnum.Pending)
        {
            throw new InvalidOperationException($"Only pending bookings can be approved. Current status: {entity.Status}");
        }

        // For monthly rentals, create Tenant and Subscription now
        if (entity.IsSubscription && _subscriptionService != null)
        {
            // Ensure a Tenant exists for this user/property pair
            var tenant = await Context.Set<Tenant>()
                .FirstOrDefaultAsync(t => t.UserId == entity.UserId && t.PropertyId == entity.PropertyId);

            if (tenant == null)
            {
                tenant = new Tenant
                {
                    UserId = entity.UserId,
                    PropertyId = entity.PropertyId,
                    LeaseStartDate = entity.StartDate,
                    LeaseEndDate = entity.EndDate,
                    TenantStatus = Domain.Models.Enums.TenantStatusEnum.Active
                };
                Context.Set<Tenant>().Add(tenant);
                await Context.SaveChangesAsync(); // obtain TenantId
            }
            else if (tenant.TenantStatus != Domain.Models.Enums.TenantStatusEnum.Active)
            {
                // Reactivate existing tenant
                tenant.TenantStatus = Domain.Models.Enums.TenantStatusEnum.Active;
                tenant.LeaseStartDate = entity.StartDate;
                tenant.LeaseEndDate = entity.EndDate;
            }

            // Create subscription for monthly rental
            var subscription = await _subscriptionService.CreateSubscriptionAsync(
                tenant.TenantId,
                entity.PropertyId,
                entity.BookingId,
                entity.TotalPrice, // monthly amount
                entity.StartDate,
                entity.EndDate);

            // Update booking with subscription reference
            entity.SubscriptionId = subscription.SubscriptionId;

            // Update property status to Occupied
            if (entity.Property != null)
            {
                entity.Property.Status = Domain.Models.Enums.PropertyStatusEnum.Occupied;
            }
        }

        // Set status based on current date vs start date
        var today = DateOnly.FromDateTime(DateTime.UtcNow);
        entity.Status = today >= entity.StartDate 
            ? Domain.Models.Enums.BookingStatusEnum.Active 
            : Domain.Models.Enums.BookingStatusEnum.Upcoming;
        
        entity.UpdatedAt = DateTime.UtcNow;
        await Context.SaveChangesAsync();

        // Notify tenant of approval
        if (_notificationService != null)
        {
            try
            {
                var propertyName = entity.Property?.Name ?? "the property";
                var startDate = entity.StartDate.ToString("MMM dd, yyyy");
                
                await _notificationService.CreateNotificationWithEmailAsync(
                    entity.UserId,
                    "Rental Application Approved",
                    $"Great news! Your rental application for {propertyName} has been approved by the landlord. " +
                    $"Your lease begins on {startDate}. You will receive payment instructions shortly.",
                    "booking_approved",
                    sendEmail: true,
                    referenceId: entity.BookingId);
            }
            catch (Exception ex)
            {
                Logger.LogError(ex, "Failed to send approval notification for booking {BookingId}", bookingId);
            }
        }

        return Mapper.Map<BookingResponse>(entity);
    }

    public async Task<BookingResponse> RejectBookingAsync(int bookingId, string? reason = null)
    {
        // Only landlords/owners from desktop can reject
        if (CurrentUser?.IsDesktop != true)
        {
            throw new InvalidOperationException("Only landlords can reject bookings.");
        }

        if (!string.IsNullOrWhiteSpace(CurrentUser.UserRole) &&
            !(string.Equals(CurrentUser.UserRole, "Owner", StringComparison.OrdinalIgnoreCase) ||
              string.Equals(CurrentUser.UserRole, "Landlord", StringComparison.OrdinalIgnoreCase)))
        {
            throw new InvalidOperationException("Only landlords can reject bookings.");
        }

        var entity = await Context.Set<Booking>()
            .Include(b => b.Property)
            .Include(b => b.User)
            .FirstOrDefaultAsync(x => x.BookingId == bookingId);

        if (entity == null)
            throw new KeyNotFoundException($"Booking with id {bookingId} not found");

        // Ensure ownership
        var ownerId = CurrentUser.GetUserIdAsInt();
        if (!ownerId.HasValue || entity.Property == null || entity.Property.OwnerId != ownerId.Value)
        {
            throw new KeyNotFoundException($"Booking with id {bookingId} not found");
        }

        // Only pending bookings can be rejected
        if (entity.Status != Domain.Models.Enums.BookingStatusEnum.Pending)
        {
            throw new InvalidOperationException($"Only pending bookings can be rejected. Current status: {entity.Status}");
        }

        // Set status to Cancelled
        entity.Status = Domain.Models.Enums.BookingStatusEnum.Cancelled;
        entity.UpdatedAt = DateTime.UtcNow;
        await Context.SaveChangesAsync();

        // Notify tenant of rejection
        if (_notificationService != null)
        {
            try
            {
                var propertyName = entity.Property?.Name ?? "the property";
                var messageBuilder = new System.Text.StringBuilder();
                messageBuilder.AppendLine($"We're sorry, your rental application for {propertyName} was not approved by the landlord.");
                
                if (!string.IsNullOrWhiteSpace(reason))
                {
                    messageBuilder.AppendLine();
                    messageBuilder.AppendLine($"Reason: {reason}");
                }
                
                messageBuilder.AppendLine();
                messageBuilder.AppendLine("You can browse other available properties on our platform.");
                
                await _notificationService.CreateNotificationWithEmailAsync(
                    entity.UserId,
                    "Rental Application Not Approved",
                    messageBuilder.ToString(),
                    "booking_rejected",
                    sendEmail: true,
                    referenceId: entity.BookingId);
            }
            catch (Exception ex)
            {
                Logger.LogError(ex, "Failed to send rejection notification for booking {BookingId}", bookingId);
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
            .Where(t => t.LeaseStartDate!.Value < bookingEnd)
            .Where(t => !t.LeaseEndDate.HasValue || t.LeaseEndDate!.Value > bookingStart)
            .AnyAsync();

        if (hasActiveTenantOverlap)
        {
            throw new InvalidOperationException("Cannot update booking: property has an active tenancy overlapping the requested dates.");
        }

        // Prevent same user from having multiple non-cancelled bookings on the same property
        // This catches cases where Tenant record doesn't exist yet (pending approval) or for daily rentals
        // Only check Confirmed/Upcoming bookings (not Pending or Cancelled)
        var hasExistingActiveBooking = await Context.Set<Booking>()
            .AsNoTracking()
            .Where(b => b.PropertyId == request.PropertyId)
            .Where(b => b.UserId == entity.UserId)
            .Where(b => b.Status == Domain.Models.Enums.BookingStatusEnum.Approved || b.Status == Domain.Models.Enums.BookingStatusEnum.Upcoming)
            // Check for date overlap using strict inequality to allow adjacent bookings
            .Where(b => b.StartDate < bookingEnd)
            .Where(b => !b.EndDate.HasValue || b.EndDate.Value > bookingStart)
            .AnyAsync();

        if (hasExistingActiveBooking)
        {
            throw new InvalidOperationException("You already have an active or upcoming booking for this property during this period.");
        }
    }

}