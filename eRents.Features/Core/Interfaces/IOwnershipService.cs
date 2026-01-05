using eRents.Domain.Models;

namespace eRents.Features.Core.Interfaces;

/// <summary>
/// Centralized service for ownership validation and scoping.
/// Eliminates duplicate ownership check logic across feature services.
/// </summary>
public interface IOwnershipService
{
    /// <summary>
    /// Check if the current user has ownership access (is a Desktop Owner/Landlord).
    /// </summary>
    bool RequiresOwnershipScoping();

    /// <summary>
    /// Get the current owner's user ID for scoping queries.
    /// Returns null if user is not an owner or doesn't require scoping.
    /// </summary>
    int? GetCurrentOwnerId();

    /// <summary>
    /// Validate that a property belongs to the current owner.
    /// Throws KeyNotFoundException if validation fails.
    /// </summary>
    /// <param name="propertyId">The property ID to validate</param>
    /// <param name="entityName">Name of the entity for error messages (e.g., "Property", "Booking")</param>
    Task ValidatePropertyOwnershipAsync(int propertyId, string entityName = "Property");

    /// <summary>
    /// Validate that a property entity belongs to the current owner.
    /// Throws KeyNotFoundException if validation fails.
    /// </summary>
    /// <param name="property">The property entity (must include OwnerId)</param>
    /// <param name="entityName">Name of the entity for error messages</param>
    void ValidatePropertyOwnership(Property property, string entityName = "Property");

    /// <summary>
    /// Validate that a booking belongs to the current owner (via property).
    /// Throws KeyNotFoundException if validation fails.
    /// </summary>
    /// <param name="bookingId">The booking ID to validate</param>
    /// <param name="entityName">Name of the entity for error messages</param>
    Task ValidateBookingOwnershipAsync(int bookingId, string entityName = "Booking");

    /// <summary>
    /// Validate that a tenant assignment belongs to the current owner (via property).
    /// Throws KeyNotFoundException if validation fails.
    /// </summary>
    /// <param name="tenant">The tenant entity (must include Property navigation)</param>
    /// <param name="entityName">Name of the entity for error messages</param>
    void ValidateTenantOwnership(Tenant tenant, string entityName = "Tenant");

    /// <summary>
    /// Validate that a maintenance issue belongs to the current owner (via property).
    /// Throws KeyNotFoundException if validation fails.
    /// </summary>
    /// <param name="issue">The maintenance issue entity (must include Property navigation)</param>
    /// <param name="entityName">Name of the entity for error messages</param>
    void ValidateMaintenanceIssueOwnership(MaintenanceIssue issue, string entityName = "Maintenance Issue");

    /// <summary>
    /// Validate that a review belongs to the current owner (via property or booking).
    /// Throws KeyNotFoundException if validation fails.
    /// </summary>
    /// <param name="review">The review entity (must include Property/Booking navigation)</param>
    /// <param name="entityName">Name of the entity for error messages</param>
    void ValidateReviewOwnership(Review review, string entityName = "Review");

    /// <summary>
    /// Apply ownership scoping to a property query (filters to current owner's properties).
    /// Returns the original query if scoping is not required.
    /// </summary>
    IQueryable<Property> ScopePropertiesQuery(IQueryable<Property> query);

    /// <summary>
    /// Apply ownership scoping to a booking query (filters to current owner's bookings via property).
    /// Returns the original query if scoping is not required.
    /// </summary>
    IQueryable<Booking> ScopeBookingsQuery(IQueryable<Booking> query);

    /// <summary>
    /// Apply ownership scoping to a tenant query (filters to current owner's tenants via property).
    /// Returns the original query if scoping is not required.
    /// </summary>
    IQueryable<Tenant> ScopeTenantsQuery(IQueryable<Tenant> query);

    /// <summary>
    /// Apply ownership scoping to a maintenance issue query (filters to current owner's issues via property).
    /// Returns the original query if scoping is not required.
    /// </summary>
    IQueryable<MaintenanceIssue> ScopeMaintenanceIssuesQuery(IQueryable<MaintenanceIssue> query);

    /// <summary>
    /// Apply ownership scoping to a review query (filters to current owner's reviews via property/booking).
    /// Returns the original query if scoping is not required.
    /// </summary>
    IQueryable<Review> ScopeReviewsQuery(IQueryable<Review> query);
}
