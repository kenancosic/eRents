using eRents.Domain.Models;
using eRents.Domain.Shared.Interfaces;
using eRents.Features.Core.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace eRents.Features.Core.Services;

/// <summary>
/// Centralized ownership validation and scoping service.
/// Consolidates duplicate ownership logic from feature services.
/// </summary>
public class OwnershipService : IOwnershipService
{
    private readonly ICurrentUserService? _currentUser;
    private readonly DbContext _context;

    public OwnershipService(DbContext context, ICurrentUserService? currentUserService = null)
    {
        _context = context;
        _currentUser = currentUserService;
    }

    /// <inheritdoc />
    public bool RequiresOwnershipScoping()
    {
        if (_currentUser == null || !_currentUser.IsAuthenticated)
            return false;

        // Desktop clients with Owner/Landlord role require ownership scoping
        return _currentUser.IsDesktop &&
               (string.Equals(_currentUser.UserRole, "Owner", StringComparison.OrdinalIgnoreCase) ||
                string.Equals(_currentUser.UserRole, "Landlord", StringComparison.OrdinalIgnoreCase));
    }

    /// <inheritdoc />
    public int? GetCurrentOwnerId()
    {
        if (!RequiresOwnershipScoping())
            return null;

        return _currentUser?.GetUserIdAsInt();
    }

    /// <inheritdoc />
    public async Task ValidatePropertyOwnershipAsync(int propertyId, string entityName = "Property")
    {
        if (!RequiresOwnershipScoping())
            return;

        var ownerId = GetCurrentOwnerId();
        if (!ownerId.HasValue)
            throw new KeyNotFoundException($"{entityName} not found");

        var property = await _context.Set<Property>()
            .AsNoTracking()
            .FirstOrDefaultAsync(p => p.PropertyId == propertyId);

        if (property == null || property.OwnerId != ownerId.Value)
            throw new KeyNotFoundException($"{entityName} not found");
    }

    /// <inheritdoc />
    public void ValidatePropertyOwnership(Property property, string entityName = "Property")
    {
        if (!RequiresOwnershipScoping())
            return;

        var ownerId = GetCurrentOwnerId();
        if (!ownerId.HasValue)
            throw new KeyNotFoundException($"{entityName} not found");

        if (property == null || property.OwnerId != ownerId.Value)
            throw new KeyNotFoundException($"{entityName} not found");
    }

    /// <inheritdoc />
    public async Task ValidateBookingOwnershipAsync(int bookingId, string entityName = "Booking")
    {
        if (!RequiresOwnershipScoping())
            return;

        var ownerId = GetCurrentOwnerId();
        if (!ownerId.HasValue)
            throw new KeyNotFoundException($"{entityName} not found");

        var booking = await _context.Set<Booking>()
            .AsNoTracking()
            .Include(b => b.Property)
            .FirstOrDefaultAsync(b => b.BookingId == bookingId);

        if (booking?.Property == null || booking.Property.OwnerId != ownerId.Value)
            throw new KeyNotFoundException($"{entityName} not found");
    }

    /// <inheritdoc />
    public void ValidateTenantOwnership(Tenant tenant, string entityName = "Tenant")
    {
        if (!RequiresOwnershipScoping())
            return;

        var ownerId = GetCurrentOwnerId();
        if (!ownerId.HasValue)
            throw new KeyNotFoundException($"{entityName} not found");

        if (tenant?.Property == null || tenant.Property.OwnerId != ownerId.Value)
            throw new KeyNotFoundException($"{entityName} not found");
    }

    /// <inheritdoc />
    public void ValidateMaintenanceIssueOwnership(MaintenanceIssue issue, string entityName = "Maintenance Issue")
    {
        if (!RequiresOwnershipScoping())
            return;

        var ownerId = GetCurrentOwnerId();
        if (!ownerId.HasValue)
            throw new KeyNotFoundException($"{entityName} not found");

        if (issue?.Property == null || issue.Property.OwnerId != ownerId.Value)
            throw new KeyNotFoundException($"{entityName} not found");
    }

    /// <inheritdoc />
    public void ValidateReviewOwnership(Review review, string entityName = "Review")
    {
        if (!RequiresOwnershipScoping())
            return;

        var ownerId = GetCurrentOwnerId();
        if (!ownerId.HasValue)
            throw new KeyNotFoundException($"{entityName} not found");

        // Check ownership via property or booking->property
        var propertyOwnerId = review.Property?.OwnerId ?? review.Booking?.Property?.OwnerId;
        if (!propertyOwnerId.HasValue || propertyOwnerId.Value != ownerId.Value)
            throw new KeyNotFoundException($"{entityName} not found");
    }

    /// <inheritdoc />
    public IQueryable<Property> ScopePropertiesQuery(IQueryable<Property> query)
    {
        if (!RequiresOwnershipScoping())
            return query;

        var ownerId = GetCurrentOwnerId();
        if (!ownerId.HasValue)
            return query.Where(p => false); // Return empty if no valid owner

        return query.Where(p => p.OwnerId == ownerId.Value);
    }

    /// <inheritdoc />
    public IQueryable<Booking> ScopeBookingsQuery(IQueryable<Booking> query)
    {
        if (!RequiresOwnershipScoping())
            return query;

        var ownerId = GetCurrentOwnerId();
        if (!ownerId.HasValue)
            return query.Where(b => false);

        return query.Where(b => b.Property != null && b.Property.OwnerId == ownerId.Value);
    }

    /// <inheritdoc />
    public IQueryable<Tenant> ScopeTenantsQuery(IQueryable<Tenant> query)
    {
        if (!RequiresOwnershipScoping())
            return query;

        var ownerId = GetCurrentOwnerId();
        if (!ownerId.HasValue)
            return query.Where(t => false);

        return query.Where(t => t.Property != null && t.Property.OwnerId == ownerId.Value);
    }

    /// <inheritdoc />
    public IQueryable<MaintenanceIssue> ScopeMaintenanceIssuesQuery(IQueryable<MaintenanceIssue> query)
    {
        if (!RequiresOwnershipScoping())
            return query;

        var ownerId = GetCurrentOwnerId();
        if (!ownerId.HasValue)
            return query.Where(m => false);

        return query.Where(m => m.Property != null && m.Property.OwnerId == ownerId.Value);
    }

    /// <inheritdoc />
    public IQueryable<Review> ScopeReviewsQuery(IQueryable<Review> query)
    {
        if (!RequiresOwnershipScoping())
            return query;

        var ownerId = GetCurrentOwnerId();
        if (!ownerId.HasValue)
            return query.Where(r => false);

        return query.Where(r =>
            (r.Property != null && r.Property.OwnerId == ownerId.Value) ||
            (r.Booking != null && r.Booking.Property != null && r.Booking.Property.OwnerId == ownerId.Value));
    }
}
