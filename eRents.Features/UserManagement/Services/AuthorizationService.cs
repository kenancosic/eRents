using eRents.Domain.Models;
using eRents.Domain.Shared.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace eRents.Features.UserManagement.Services;

/// <summary>
/// Service for handling authorization business logic across the application
/// Uses ERentsContext directly - no repository layer
/// Organized under UserManagement as it deals with user authorization
/// </summary>
public class AuthorizationService : IAuthorizationService
{
    private readonly ERentsContext _context;
    private readonly ICurrentUserService _currentUserService;
    private readonly ILogger<AuthorizationService> _logger;

    public AuthorizationService(
        ERentsContext context,
        ICurrentUserService currentUserService,
        ILogger<AuthorizationService> logger)
    {
        _context = context;
        _currentUserService = currentUserService;
        _logger = logger;
    }

    /// <summary>
    /// Check if user can approve a rental request
    /// </summary>
    public async Task<bool> CanUserApproveRentalRequestAsync(int userId, int rentalRequestId)
    {
        try
        {
            var rentalRequest = await _context.RentalRequests
                .Include(rr => rr.Property)
                .FirstOrDefaultAsync(rr => rr.RequestId == rentalRequestId);

            if (rentalRequest?.Property == null)
                return false;

            // User can approve if they own the property
            bool canApprove = rentalRequest.Property.OwnerId == userId;

            _logger.LogInformation("Authorization check for rental request approval: UserId={UserId}, RequestId={RequestId}, CanApprove={CanApprove}",
                userId, rentalRequestId, canApprove);

            return canApprove;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error checking rental request approval authorization for user {UserId} and request {RequestId}",
                userId, rentalRequestId);
            return false;
        }
    }

    /// <summary>
    /// Check if user can cancel a booking
    /// </summary>
    public async Task<bool> CanUserCancelBookingAsync(int userId, int bookingId)
    {
        try
        {
            var booking = await _context.Bookings
                .Include(b => b.Property)
                .FirstOrDefaultAsync(b => b.BookingId == bookingId);

            if (booking?.Property == null)
                return false;

            // User can cancel if they made the booking or own the property
            bool canCancel = booking.UserId == userId || booking.Property.OwnerId == userId;

            _logger.LogInformation("Authorization check for booking cancellation: UserId={UserId}, BookingId={BookingId}, CanCancel={CanCancel}",
                userId, bookingId, canCancel);

            return canCancel;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error checking booking cancellation authorization for user {UserId} and booking {BookingId}",
                userId, bookingId);
            return false;
        }
    }

    /// <summary>
    /// Check if user can modify a property
    /// </summary>
    public async Task<bool> CanUserModifyPropertyAsync(int userId, int propertyId)
    {
        try
        {
            var property = await _context.Properties
                .FirstOrDefaultAsync(p => p.PropertyId == propertyId);

            return property?.OwnerId == userId;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error checking property authorization");
            return false;
        }
    }

    /// <summary>
    /// Check if user can view tenant information
    /// </summary>
    public async Task<bool> CanUserViewTenantAsync(int userId, int tenantId)
    {
        try
        {
            // Users can view their own information
            if (userId == tenantId)
                return true;

            // Landlords can view tenants who have relationships with their properties
            var hasRelationship = await _context.RentalRequests
                .Include(rr => rr.Property)
                .AnyAsync(rr => rr.UserId == tenantId && 
                               rr.Property != null && 
                               rr.Property.OwnerId == userId);

            _logger.LogInformation("Authorization check for tenant viewing: UserId={UserId}, TenantId={TenantId}, CanView={CanView}",
                userId, tenantId, hasRelationship);

            return hasRelationship;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error checking tenant viewing authorization for user {UserId} and tenant {TenantId}",
                userId, tenantId);
            return false;
        }
    }

    /// <summary>
    /// Check if user can manage maintenance requests
    /// </summary>
    public async Task<bool> CanUserManageMaintenanceAsync(int userId, int maintenanceId)
    {
        try
        {
            var maintenance = await _context.MaintenanceIssues
                .Include(m => m.Property)
                .FirstOrDefaultAsync(m => m.MaintenanceIssueId == maintenanceId);

            if (maintenance?.Property == null)
                return false;

            // User can manage if they reported the issue or own the property
            bool canManage = maintenance.ReportedByUserId == userId || maintenance.Property.OwnerId == userId;

            _logger.LogInformation("Authorization check for maintenance management: UserId={UserId}, MaintenanceId={MaintenanceId}, CanManage={CanManage}",
                userId, maintenanceId, canManage);

            return canManage;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error checking maintenance management authorization for user {UserId} and maintenance {MaintenanceId}",
                userId, maintenanceId);
            return false;
        }
    }

    /// <summary>
    /// Check if user can access financial reports
    /// </summary>
    public async Task<bool> CanUserAccessFinancialReportsAsync(int userId)
    {
        try
        {
            // Only landlords can access financial reports
            var user = await _context.Users
                .Include(u => u.UserTypeNavigation)
                .FirstOrDefaultAsync(u => u.UserId == userId);

            if (user?.UserTypeNavigation == null)
                return false;

            bool canAccess = user.UserTypeNavigation.TypeName == "Landlord";

            _logger.LogInformation("Authorization check for financial reports access: UserId={UserId}, CanAccess={CanAccess}",
                userId, canAccess);

            return canAccess;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error checking financial reports authorization for user {UserId}", userId);
            return false;
        }
    }

    /// <summary>
    /// Check if user can manage reviews
    /// </summary>
    public async Task<bool> CanUserManageReviewAsync(int userId, int reviewId)
    {
        try
        {
            var review = await _context.Reviews
                .Include(r => r.Property)
                .FirstOrDefaultAsync(r => r.ReviewId == reviewId);

            if (review?.Property == null)
                return false;

            // User can manage if they wrote the review or own the property
            bool canManage = review.ReviewerId == userId || review.Property.OwnerId == userId;

            _logger.LogInformation("Authorization check for review management: UserId={UserId}, ReviewId={ReviewId}, CanManage={CanManage}",
                userId, reviewId, canManage);

            return canManage;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error checking review management authorization for user {UserId} and review {ReviewId}",
                userId, reviewId);
            return false;
        }
    }

    /// <summary>
    /// Check if user has specific role
    /// </summary>
    public async Task<bool> HasRoleAsync(int userId, params string[] roles)
    {
        try
        {
            var user = await _context.Users
                .Include(u => u.UserTypeNavigation)
                .FirstOrDefaultAsync(u => u.UserId == userId);

            if (user?.UserTypeNavigation == null)
                return false;

            bool hasRole = roles.Any(role => string.Equals(user.UserTypeNavigation.TypeName, role, StringComparison.OrdinalIgnoreCase));

            _logger.LogInformation("Role check: UserId={UserId}, RequiredRoles=[{Roles}], UserRole={UserRole}, HasRole={HasRole}",
                userId, string.Join(",", roles), user.UserTypeNavigation.TypeName, hasRole);

            return hasRole;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error checking roles for user {UserId}", userId);
            return false;
        }
    }

    /// <summary>
    /// Check if current user can perform action on behalf of target user
    /// </summary>
    public async Task<bool> CanActOnBehalfOfUserAsync(int targetUserId)
    {
        try
        {
            var currentUserId = _currentUserService.GetUserIdAsInt();
            
            // Users can always act on their own behalf
            if (currentUserId == targetUserId)
                return true;

            // Check if current user is a landlord and target user is their tenant
            var currentUserRole = _currentUserService.UserRole;
            if (currentUserRole == "Landlord")
            {
                var hasRelationship = await _context.RentalRequests
                    .Include(rr => rr.Property)
                    .AnyAsync(rr => rr.UserId == targetUserId && 
                                   rr.Property != null && 
                                   rr.Property.OwnerId == currentUserId);

                return hasRelationship;
            }

            return false;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error checking act-on-behalf authorization for target user {TargetUserId}", targetUserId);
            return false;
        }
    }
} 