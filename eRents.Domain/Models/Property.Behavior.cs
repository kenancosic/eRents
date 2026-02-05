using eRents.Domain.Models.Enums;

namespace eRents.Domain.Models;

/// <summary>
/// Domain behavior methods for the Property entity.
/// These methods encapsulate business rules for property availability and status.
/// </summary>
public partial class Property
{
    /// <summary>
    /// Checks if the property is available for the specified date range.
    /// Considers: maintenance flag, unavailable dates, and (optionally) active tenant.
    /// Note: Does NOT check existing bookings - use WouldAcceptBooking for that.
    /// </summary>
    /// <param name="startDate">Start of date range</param>
    /// <param name="endDate">End of date range</param>
    /// <param name="reason">Output parameter describing why unavailable, if applicable</param>
    /// <returns>True if property state allows bookings for this range</returns>
    public bool IsAvailableFor(DateOnly startDate, DateOnly endDate, out string? reason)
    {
        reason = null;

        // Check under maintenance
        if (IsUnderMaintenance)
        {
            reason = "Property is under maintenance";
            return false;
        }

        // Check unavailable date range
        if (UnavailableFrom.HasValue)
        {
            var unavailableTo = UnavailableTo ?? DateOnly.MaxValue;
            if (startDate <= unavailableTo && endDate >= UnavailableFrom.Value)
            {
                reason = $"Property is unavailable from {UnavailableFrom:yyyy-MM-dd} to {UnavailableTo:yyyy-MM-dd}";
                return false;
            }
        }

        return true;
    }

    /// <summary>
    /// Checks if the property would accept a new booking for the specified dates,
    /// considering existing bookings.
    /// </summary>
    /// <param name="startDate">Booking start date</param>
    /// <param name="endDate">Booking end date</param>
    /// <param name="existingBookings">Current confirmed/upcoming bookings</param>
    /// <param name="excludeBookingId">Optional booking ID to exclude from overlap check (for updates)</param>
    /// <returns>True if no conflicts exist</returns>
    public bool WouldAcceptBooking(DateOnly startDate, DateOnly endDate, IEnumerable<Booking> existingBookings, int? excludeBookingId = null)
    {
        // First check property state
        if (!IsAvailableFor(startDate, endDate, out _))
            return false;

        // Check for overlapping bookings
        var relevantStatuses = new[] { BookingStatusEnum.Approved, BookingStatusEnum.Upcoming };

        return !existingBookings.Any(b =>
        {
            if (excludeBookingId.HasValue && b.BookingId == excludeBookingId.Value)
                return false;

            if (!relevantStatuses.Contains(b.Status))
                return false;

            // Overlap: existing.Start < request.End AND existing.End > request.Start
            return b.StartDate < endDate && (b.EndDate ?? DateOnly.MaxValue) > startDate;
        });
    }

    /// <summary>
    /// Gets conflicting bookings for a proposed date range.
    /// </summary>
    /// <param name="startDate">Booking start date</param>
    /// <param name="endDate">Booking end date</param>
    /// <param name="existingBookings">All existing bookings</param>
    /// <param name="excludeBookingId">Optional booking ID to exclude</param>
    /// <returns>IDs of conflicting bookings</returns>
    public IEnumerable<int> GetConflictingBookings(DateOnly startDate, DateOnly endDate, IEnumerable<Booking> existingBookings, int? excludeBookingId = null)
    {
        var relevantStatuses = new[] { BookingStatusEnum.Approved, BookingStatusEnum.Upcoming };

        return existingBookings
            .Where(b =>
            {
                if (excludeBookingId.HasValue && b.BookingId == excludeBookingId.Value)
                    return false;

                if (!relevantStatuses.Contains(b.Status))
                    return false;

                return b.StartDate < endDate && (b.EndDate ?? DateOnly.MaxValue) > startDate;
            })
            .Select(b => b.BookingId);
    }

    /// <summary>
    /// Determines if the property has an active tenant as of a specific date.
    /// </summary>
    /// <param name="activeTenants">Collection of tenant records for this property</param>
    /// <param name="asOfDate">Date to check (defaults to today)</param>
    /// <returns>True if an active tenant exists</returns>
    public bool HasActiveTenant(IEnumerable<Tenant> activeTenants, DateOnly? asOfDate = null)
    {
        var checkDate = asOfDate ?? DateOnly.FromDateTime(DateTime.UtcNow);

        return activeTenants.Any(t =>
            t.TenantStatus == TenantStatusEnum.Active &&
            (!t.LeaseEndDate.HasValue || t.LeaseEndDate >= checkDate));
    }

    /// <summary>
    /// Computes the effective property status based on current state and tenant occupancy.
    /// </summary>
    /// <param name="activeTenants">Active tenants for this property</param>
    /// <param name="asOfDate">Date to compute status for (defaults to today)</param>
    /// <returns>Computed property status</returns>
    public PropertyStatusEnum ComputeStatus(IEnumerable<Tenant> activeTenants, DateOnly? asOfDate = null)
    {
        var checkDate = asOfDate ?? DateOnly.FromDateTime(DateTime.UtcNow);

        // Hierarchy: Occupied > UnderMaintenance > Unavailable > Available

        if (HasActiveTenant(activeTenants, checkDate))
            return PropertyStatusEnum.Occupied;

        if (IsUnderMaintenance)
            return PropertyStatusEnum.UnderMaintenance;

        if (UnavailableFrom.HasValue &&
            UnavailableFrom <= checkDate &&
            (UnavailableTo ?? DateOnly.MaxValue) >= checkDate)
        {
            return PropertyStatusEnum.Unavailable;
        }

        return PropertyStatusEnum.Available;
    }

    /// <summary>
    /// Checks if a specific date falls within the property's unavailable range.
    /// </summary>
    /// <param name="date">Date to check</param>
    /// <returns>True if date is within unavailable range</returns>
    public bool IsDateUnavailable(DateOnly date)
    {
        if (!UnavailableFrom.HasValue)
            return false;

        var unavailableTo = UnavailableTo ?? DateOnly.MaxValue;
        return date >= UnavailableFrom.Value && date <= unavailableTo;
    }

    /// <summary>
    /// Validates if a status change is allowed based on current property state.
    /// </summary>
    /// <param name="newStatus">Desired status</param>
    /// <param name="currentTenants">Current tenant records</param>
    /// <param name="reason">Output reason if change not allowed</param>
    /// <returns>True if status change is valid</returns>
    public bool CanTransitionToStatus(PropertyStatusEnum newStatus, IEnumerable<Tenant> currentTenants, out string? reason)
    {
        reason = null;
        var currentStatus = ComputeStatus(currentTenants);

        // Occupied properties can only become Available when tenant leaves (handled by tenancy end)
        if (currentStatus == PropertyStatusEnum.Occupied && newStatus != PropertyStatusEnum.Occupied)
        {
            if (HasActiveTenant(currentTenants))
            {
                reason = "Cannot change status while property has an active tenant";
                return false;
            }
        }

        // Cannot set to UnderMaintenance if has active tenant
        if (newStatus == PropertyStatusEnum.UnderMaintenance && HasActiveTenant(currentTenants))
        {
            reason = "Cannot set to maintenance mode while property is occupied";
            return false;
        }

        return true;
    }
}
