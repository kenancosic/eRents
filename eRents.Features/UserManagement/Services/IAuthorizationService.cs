namespace eRents.Features.UserManagement.Services;

/// <summary>
/// Interface for authorization business logic across the application
/// Supports dependency injection and testing patterns
/// </summary>
public interface IAuthorizationService
{
    /// <summary>
    /// Check if user can approve a rental request
    /// </summary>
    Task<bool> CanUserApproveRentalRequestAsync(int userId, int rentalRequestId);

    /// <summary>
    /// Check if user can cancel a booking
    /// </summary>
    Task<bool> CanUserCancelBookingAsync(int userId, int bookingId);

    /// <summary>
    /// Check if user can modify a property
    /// </summary>
    Task<bool> CanUserModifyPropertyAsync(int userId, int propertyId);

    /// <summary>
    /// Check if user can view tenant information
    /// </summary>
    Task<bool> CanUserViewTenantAsync(int userId, int tenantId);

    /// <summary>
    /// Check if user can manage maintenance requests
    /// </summary>
    Task<bool> CanUserManageMaintenanceAsync(int userId, int maintenanceId);

    /// <summary>
    /// Check if user can access financial reports
    /// </summary>
    Task<bool> CanUserAccessFinancialReportsAsync(int userId);

    /// <summary>
    /// Check if user can manage reviews
    /// </summary>
    Task<bool> CanUserManageReviewAsync(int userId, int reviewId);

    /// <summary>
    /// Check if user has specific role
    /// </summary>
    Task<bool> HasRoleAsync(int userId, params string[] roles);

    /// <summary>
    /// Check if current user can perform action on behalf of target user
    /// </summary>
    Task<bool> CanActOnBehalfOfUserAsync(int targetUserId);
} 