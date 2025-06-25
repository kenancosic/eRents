using System.Threading.Tasks;

namespace eRents.Application.Services.UserService.AuthorizationService
{
    /// <summary>
    /// Service for handling authorization business logic across the application
    /// Extracted from RentalCoordinatorService to maintain proper SoC
    /// Organized under UserService as it deals with user authorization
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
        /// Check if user can perform administrative actions
        /// </summary>
        Task<bool> CanUserPerformAdminActionsAsync(int userId);

        /// <summary>
        /// Check if user can manage reviews
        /// </summary>
        Task<bool> CanUserManageReviewAsync(int userId, int reviewId);
    }
} 