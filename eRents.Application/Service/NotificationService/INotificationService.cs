namespace eRents.Application.Service.NotificationService
{
    /// <summary>
    /// Service for managing notifications to users
    /// Used by ContractExpirationService to notify users about contract status
    /// </summary>
    public interface INotificationService
    {
        /// <summary>
        /// Create a new notification for a user
        /// </summary>
        Task CreateNotificationAsync(int userId, string title, string message, string type);
        
        /// <summary>
        /// Get unread notifications for a user
        /// </summary>
        Task<List<NotificationResponse>> GetUnreadNotificationsAsync(int userId);
        
        /// <summary>
        /// Mark notification as read
        /// </summary>
        Task MarkAsReadAsync(int notificationId);
        
        /// <summary>
        /// Send email notification (future enhancement)
        /// </summary>
        Task SendEmailNotificationAsync(int userId, string subject, string message);
    }
    
    /// <summary>
    /// Simple notification response DTO
    /// </summary>
    public class NotificationResponse
    {
        public int NotificationId { get; set; }
        public int UserId { get; set; }
        public string Title { get; set; } = string.Empty;
        public string Message { get; set; } = string.Empty;
        public string Type { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
        public bool IsRead { get; set; }
    }
} 