using eRents.Features.Core.Models.Shared;

namespace eRents.Features.Shared.Services
{
    /// <summary>
    /// Service for managing user notifications with database persistence
    /// Provides both in-app notifications and email notification capabilities
    /// </summary>
    public interface INotificationService
    {
        #region Core Notification Operations

        Task CreateNotificationAsync(int userId, string title, string message, string type, int? referenceId = null);
        Task<List<NotificationResponse>> GetUnreadNotificationsAsync(int userId);
        Task<List<NotificationResponse>> GetNotificationsAsync(int userId, int skip = 0, int take = 20);
        Task MarkAsReadAsync(int notificationId);
        Task MarkAllAsReadAsync(int userId);
        Task DeleteNotificationAsync(int notificationId);
        Task<int> GetUnreadCountAsync(int userId);

        #endregion

        #region Specialized Notification Methods

        Task CreateBookingNotificationAsync(int userId, int bookingId, string title, string message);
        Task CreateMaintenanceNotificationAsync(int userId, int maintenanceIssueId, string title, string message);
        Task CreateReviewNotificationAsync(int userId, int reviewId, string title, string message);
        Task CreatePropertyNotificationAsync(int userId, int propertyId, string title, string message);
        Task CreateSystemNotificationAsync(int userId, string title, string message);

        #endregion

        #region Email Integration

        Task SendEmailNotificationAsync(int userId, string subject, string message);
        Task CreateNotificationWithEmailAsync(int userId, string title, string message, string type,
            bool sendEmail = false, int? referenceId = null);

        #endregion
    }
}