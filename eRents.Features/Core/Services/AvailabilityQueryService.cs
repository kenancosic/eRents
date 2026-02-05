using eRents.Domain.Models;
using eRents.Domain.Models.Enums;
using Microsoft.EntityFrameworkCore;

namespace eRents.Features.Core.Services;

/// <summary>
/// Implementation of availability queries using EF Core.
/// Centralizes all property availability logic to eliminate duplication across services.
/// </summary>
public class AvailabilityQueryService : IAvailabilityQueryService
{
    private readonly DbContext _context;

    public AvailabilityQueryService(DbContext context)
    {
        _context = context ?? throw new ArgumentNullException(nameof(context));
    }

    /// <inheritdoc />
    public async Task<bool> IsPropertyAvailableAsync(int propertyId, DateOnly startDate, DateOnly endDate, CancellationToken cancellationToken = default)
    {
        var property = await _context.Set<Property>()
            .AsNoTracking()
            .Include(p => p.Bookings)
            .FirstOrDefaultAsync(p => p.PropertyId == propertyId, cancellationToken);

        if (property == null)
            return false;

        // Check maintenance flag
        if (property.IsUnderMaintenance)
            return false;

        // Check unavailable date range (for daily rentals)
        if (property.UnavailableFrom.HasValue)
        {
            var unavailableTo = property.UnavailableTo ?? DateOnly.MaxValue;
            if (startDate <= unavailableTo && endDate >= property.UnavailableFrom.Value)
                return false;
        }

        // Check active tenant
        if (await HasActiveTenantAsync(propertyId, startDate, cancellationToken))
            return false;

        // Check overlapping bookings (Confirmed/Upcoming only)
        var hasConflict = property.Bookings.Any(b =>
            (b.Status == BookingStatusEnum.Approved || b.Status == BookingStatusEnum.Upcoming) &&
            b.StartDate < endDate &&
            (b.EndDate ?? DateOnly.MaxValue) > startDate);

        return !hasConflict;
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<DateOnly>> GetUnavailableDatesAsync(int propertyId, DateOnly startDate, DateOnly endDate, CancellationToken cancellationToken = default)
    {
        var unavailableDates = new List<DateOnly>();
        var property = await _context.Set<Property>()
            .AsNoTracking()
            .Include(p => p.Bookings)
            .FirstOrDefaultAsync(p => p.PropertyId == propertyId, cancellationToken);

        if (property == null)
            return unavailableDates;

        // Generate all dates in range
        for (var date = startDate; date <= endDate; date = date.AddDays(1))
        {
            if (!await IsDateAvailableAsync(property, date, cancellationToken))
            {
                unavailableDates.Add(date);
            }
        }

        return unavailableDates;
    }

    /// <inheritdoc />
    public async Task ValidateNoOverlapAsync(int propertyId, DateOnly startDate, DateOnly endDate, int? excludeBookingId = null, CancellationToken cancellationToken = default)
    {
        var conflictingIds = await GetConflictingBookingsAsync(propertyId, startDate, endDate, excludeBookingId, cancellationToken);

        if (conflictingIds.Any())
        {
            throw new InvalidOperationException(
                $"The requested dates overlap with existing booking(s): {string.Join(", ", conflictingIds)}. " +
                "Please select different dates.");
        }
    }

    /// <inheritdoc />
    public async Task<bool> HasActiveTenantAsync(int propertyId, DateOnly? asOfDate = null, CancellationToken cancellationToken = default)
    {
        var checkDate = asOfDate ?? DateOnly.FromDateTime(DateTime.UtcNow);

        return await _context.Set<Tenant>()
            .AsNoTracking()
            .AnyAsync(t =>
                t.PropertyId == propertyId &&
                t.TenantStatus == TenantStatusEnum.Active &&
                (!t.LeaseEndDate.HasValue || t.LeaseEndDate >= checkDate),
            cancellationToken);
    }

    /// <inheritdoc />
    public async Task<PropertyStatusEnum> ComputePropertyStatusAsync(int propertyId, CancellationToken cancellationToken = default)
    {
        var today = DateOnly.FromDateTime(DateTime.UtcNow);

        var property = await _context.Set<Property>()
            .AsNoTracking()
            .FirstOrDefaultAsync(p => p.PropertyId == propertyId, cancellationToken);

        if (property == null)
            return PropertyStatusEnum.Available;

        // Hierarchy: Occupied > UnderMaintenance > Unavailable > Available

        // Check for active tenant (Occupied takes precedence)
        if (await HasActiveTenantAsync(propertyId, today, cancellationToken))
            return PropertyStatusEnum.Occupied;

        // Check under maintenance
        if (property.IsUnderMaintenance)
            return PropertyStatusEnum.UnderMaintenance;

        // Check unavailable dates
        if (property.UnavailableFrom.HasValue &&
            property.UnavailableFrom <= today &&
            (property.UnavailableTo ?? DateOnly.MaxValue) >= today)
        {
            return PropertyStatusEnum.Unavailable;
        }

        return PropertyStatusEnum.Available;
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<int>> GetConflictingBookingsAsync(int propertyId, DateOnly startDate, DateOnly endDate, int? excludeBookingId = null, CancellationToken cancellationToken = default)
    {
        var query = _context.Set<Booking>()
            .AsNoTracking()
            .Where(b =>
                b.PropertyId == propertyId &&
                (b.Status == BookingStatusEnum.Approved || b.Status == BookingStatusEnum.Upcoming) &&
                b.StartDate < endDate &&
                (b.EndDate ?? DateOnly.MaxValue) > startDate);

        if (excludeBookingId.HasValue)
        {
            query = query.Where(b => b.BookingId != excludeBookingId.Value);
        }

        var conflictingIds = await query
            .Select(b => b.BookingId)
            .ToListAsync(cancellationToken);

        return conflictingIds;
    }

    /// <summary>
    /// Checks if a single date is available for a property (internal helper).
    /// </summary>
    private async Task<bool> IsDateAvailableAsync(Property property, DateOnly date, CancellationToken cancellationToken)
    {
        // Under maintenance
        if (property.IsUnderMaintenance)
            return false;

        // Unavailable date range
        if (property.UnavailableFrom.HasValue && property.UnavailableTo.HasValue)
        {
            if (date >= property.UnavailableFrom.Value && date <= property.UnavailableTo.Value)
                return false;
        }

        // Active tenant
        if (await HasActiveTenantAsync(property.PropertyId, date, cancellationToken))
            return false;

        // Existing booking
        var hasBooking = property.Bookings.Any(b =>
            (b.Status == BookingStatusEnum.Approved || b.Status == BookingStatusEnum.Upcoming) &&
            b.StartDate <= date &&
            (b.EndDate ?? DateOnly.MaxValue) >= date);

        return !hasBooking;
    }
}
