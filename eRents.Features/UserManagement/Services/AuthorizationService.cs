/*
 * SIMPLIFIED FOR ACADEMIC PURPOSES
 *
 * Original AuthorizationService.cs removed as part of Phase 7B: Enterprise Feature Removal
 *
 * The original service contained 290 lines of complex enterprise authorization logic including:
 * - Complex relationship-based permissions
 * - Advanced "act on behalf" functionality
 * - Financial reporting authorization (already removed)
 * - Complex review and tenant management permissions
 *
 * Replaced with simplified version focusing on basic Owner/Tenant role authorization
 * for academic thesis requirements.
 *
 * Removed: January 30, 2025
 * Reason: Simplify authentication system to basic Owner/Tenant roles per Phase 7B requirements
 */

using eRents.Domain.Models;
using eRents.Domain.Shared.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace eRents.Features.UserManagement.Services;

/// <summary>
/// Simplified authorization service for academic thesis requirements
/// Focuses on basic Owner/Tenant role authorization and property ownership checks
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
    /// Check if user can approve a rental request (property owners only)
    /// </summary>
    public async Task<bool> CanUserApproveRentalRequestAsync(int userId, int rentalRequestId)
    {
        try
        {
            var rentalRequest = await _context.RentalRequests
                .Include(rr => rr.Property)
                .FirstOrDefaultAsync(rr => rr.RequestId == rentalRequestId);

            return rentalRequest?.Property?.OwnerId == userId;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error checking rental request approval authorization");
            return false;
        }
    }

    /// <summary>
    /// Check if user can cancel a booking (booking creator or property owner)
    /// </summary>
    public async Task<bool> CanUserCancelBookingAsync(int userId, int bookingId)
    {
        try
        {
            var booking = await _context.Bookings
                .Include(b => b.Property)
                .FirstOrDefaultAsync(b => b.BookingId == bookingId);

            return booking != null &&
                   (booking.UserId == userId || booking.Property?.OwnerId == userId);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error checking booking cancellation authorization");
            return false;
        }
    }

    /// <summary>
    /// Check if user can modify a property (property owners only)
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
            _logger.LogError(ex, "Error checking property modification authorization");
            return false;
        }
    }

    /// <summary>
    /// Check if user can view tenant information (self only for simplified system)
    /// </summary>
    public async Task<bool> CanUserViewTenantAsync(int userId, int tenantId)
    {
        // Simplified: users can only view their own information
        return userId == tenantId;
    }

    /// <summary>
    /// Check if user can manage maintenance requests (reporter or property owner)
    /// </summary>
    public async Task<bool> CanUserManageMaintenanceAsync(int userId, int maintenanceId)
    {
        try
        {
            var maintenance = await _context.MaintenanceIssues
                .Include(m => m.Property)
                .FirstOrDefaultAsync(m => m.MaintenanceIssueId == maintenanceId);

            return maintenance != null &&
                   (maintenance.ReportedByUserId == userId ||
                    maintenance.Property?.OwnerId == userId);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error checking maintenance management authorization");
            return false;
        }
    }

    /// <summary>
    /// Financial reports authorization - removed as part of enterprise feature simplification
    /// </summary>
    public async Task<bool> CanUserAccessFinancialReportsAsync(int userId)
    {
        // Financial reporting services were removed in Phase 7B
        return false;
    }

    /// <summary>
    /// Check if user can manage reviews (review author only for simplified system)
    /// </summary>
    public async Task<bool> CanUserManageReviewAsync(int userId, int reviewId)
    {
        try
        {
            var review = await _context.Reviews
                .FirstOrDefaultAsync(r => r.ReviewId == reviewId);

            // Simplified: only review authors can manage their reviews
            return review?.ReviewerId == userId;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error checking review management authorization");
            return false;
        }
    }

    /// <summary>
    /// Check if user has specific role (basic role checking)
    /// </summary>
    public async Task<bool> HasRoleAsync(int userId, params string[] roles)
    {
        try
        {
            var user = await _context.Users
                .FirstOrDefaultAsync(u => u.UserId == userId);

            if (user == null)
                return false;

            return roles.Any(role =>
                string.Equals(user.UserType.ToString(), role, StringComparison.OrdinalIgnoreCase));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error checking user roles");
            return false;
        }
    }

    /// <summary>
    /// Check if current user can act on behalf of target user (self only for simplified system)
    /// </summary>
    public async Task<bool> CanActOnBehalfOfUserAsync(int targetUserId)
    {
        // Simplified: users can only act on their own behalf
        var currentUserId = _currentUserService.GetUserIdAsInt();
        return currentUserId == targetUserId;
    }
}