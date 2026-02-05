using eRents.Domain.Models;
using eRents.Domain.Models.Enums;

namespace eRents.Features.Core.Services;

/// <summary>
/// Centralized service for all property availability queries.
/// Single source of truth for availability checks, overlap detection, and status computation.
/// </summary>
public interface IAvailabilityQueryService
{
    /// <summary>
    /// Checks if a property is available for the specified date range.
    /// Considers: under maintenance, unavailable dates, active tenants, and existing bookings.
    /// </summary>
    Task<bool> IsPropertyAvailableAsync(int propertyId, DateOnly startDate, DateOnly endDate, CancellationToken cancellationToken = default);

    /// <summary>
    /// Gets all unavailable dates for a property within a date range.
    /// Includes: maintenance periods, unavailable date ranges, tenant occupancy, and existing bookings.
    /// </summary>
    Task<IReadOnlyList<DateOnly>> GetUnavailableDatesAsync(int propertyId, DateOnly startDate, DateOnly endDate, CancellationToken cancellationToken = default);

    /// <summary>
    /// Validates that no overlapping bookings exist for the specified date range.
    /// Throws exception if overlap detected.
    /// </summary>
    /// <exception cref="InvalidOperationException">Thrown when overlapping booking exists</exception>
    Task ValidateNoOverlapAsync(int propertyId, DateOnly startDate, DateOnly endDate, int? excludeBookingId = null, CancellationToken cancellationToken = default);

    /// <summary>
    /// Checks if a property has an active tenant as of a specific date.
    /// </summary>
    Task<bool> HasActiveTenantAsync(int propertyId, DateOnly? asOfDate = null, CancellationToken cancellationToken = default);

    /// <summary>
    /// Computes the effective status of a property based on current state.
    /// Hierarchy: Occupied > UnderMaintenance > Unavailable > Available
    /// </summary>
    Task<PropertyStatusEnum> ComputePropertyStatusAsync(int propertyId, CancellationToken cancellationToken = default);

    /// <summary>
    /// Checks for booking conflicts within a date range.
    /// Returns conflicting booking IDs if any exist.
    /// </summary>
    Task<IReadOnlyList<int>> GetConflictingBookingsAsync(int propertyId, DateOnly startDate, DateOnly endDate, int? excludeBookingId = null, CancellationToken cancellationToken = default);
}
