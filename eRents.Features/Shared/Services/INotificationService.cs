using eRents.Features.Shared.DTOs;

namespace eRents.Features.Shared.Services
{
    /// <summary>
    /// Service for managing user notifications with database persistence
    /// Provides both in-app notifications and email notification capabilities
    /// </summary>
    public interface INotificationService
    {
        #region Core Notification Operations

        /// <summary>
        /// Create a new notification for a user
        /// </summary>
        Task CreateNotificationAsync(int userId, string title, string message, string type, int? referenceId = null);
        
        /// <summary>
        /// Get unread notifications for a user
        /// </summary>
        Task<List<NotificationResponse>> GetUnreadNotificationsAsync(int userId);

        /// <summary>
        /// Get all notifications for a user (with pagination)
        /// </summary>
        Task<List<NotificationResponse>> GetNotificationsAsync(int userId, int skip = 0, int take = 20);
        
        /// <summary>
        /// Mark notification as read
        /// </summary>
        Task MarkAsReadAsync(int notificationId);

        /// <summary>
        /// Mark all notifications as read for a user
        /// </summary>
        Task MarkAllAsReadAsync(int userId);

        /// <summary>
        /// Delete a notification
        /// </summary>
        Task DeleteNotificationAsync(int notificationId);

        /// <summary>
        /// Get notification count for a user
        /// </summary>
        Task<int> GetUnreadCountAsync(int userId);

        #endregion

        #region Specialized Notification Methods

        /// <summary>
        /// Create booking-related notification
        /// </summary>
        Task CreateBookingNotificationAsync(int userId, int bookingId, string title, string message);

        /// <summary>
        /// Create maintenance-related notification
        /// </summary>
        Task CreateMaintenanceNotificationAsync(int userId, int maintenanceIssueId, string title, string message);

        /// <summary>
        /// Create review-related notification
        /// </summary>
        Task CreateReviewNotificationAsync(int userId, int reviewId, string title, string message);

        /// <summary>
        /// Create property-related notification
        /// </summary>
        Task CreatePropertyNotificationAsync(int userId, int propertyId, string title, string message);

        /// <summary>
        /// Create system notification
        /// </summary>
        Task CreateSystemNotificationAsync(int userId, string title, string message);

        #endregion

        #region Email Integration

        /// <summary>
        /// Send email notification (future enhancement)
        /// </summary>
        Task SendEmailNotificationAsync(int userId, string subject, string message);

        /// <summary>
        /// Send notification with optional email
        /// </summary>
        Task CreateNotificationWithEmailAsync(int userId, string title, string message, string type, 
            bool sendEmail = false, int? referenceId = null);

        #endregion
    }
} 