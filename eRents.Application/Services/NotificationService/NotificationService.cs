using Microsoft.Extensions.Logging;
using eRents.Shared.DTO.Response;

namespace eRents.Application.Services.NotificationService
{
    /// <summary>
    /// Simple notification service implementation for contract expiration notifications
    /// Phase 3 implementation - can be enhanced later with database storage and email integration
    /// </summary>
    public class NotificationService : INotificationService
    {
        private readonly ILogger<NotificationService> _logger;

        public NotificationService(ILogger<NotificationService> logger)
        {
            _logger = logger;
        }

        public async Task CreateNotificationAsync(int userId, string title, string message, string type)
        {
            // Phase 3 simple implementation - log the notification
            // TODO: Phase 4 enhancement - Store in database and send emails
            
            _logger.LogInformation("📧 NOTIFICATION for User {UserId}: [{Type}] {Title} - {Message}", 
                userId, type, title, message);
                
            // Future enhancement: Store in Notification entity in database
            // Future enhancement: Send email via email service
            // Future enhancement: Push notification to mobile apps
            
            await Task.CompletedTask;
        }

        public async Task<List<NotificationResponse>> GetUnreadNotificationsAsync(int userId)
        {
            // Phase 3 simple implementation - return empty list
            // TODO: Phase 4 enhancement - Query from database
            
            _logger.LogInformation("Getting unread notifications for user {UserId}", userId);
            return new List<NotificationResponse>();
        }

        public async Task MarkAsReadAsync(int notificationId)
        {
            // Phase 3 simple implementation - log the action
            // TODO: Phase 4 enhancement - Update database record
            
            _logger.LogInformation("Marking notification {NotificationId} as read", notificationId);
            await Task.CompletedTask;
        }

        public async Task SendEmailNotificationAsync(int userId, string subject, string message)
        {
            // Phase 3 simple implementation - log the email
            // TODO: Phase 4 enhancement - Send actual email via email service
            
            _logger.LogInformation("📧 EMAIL for User {UserId}: {Subject} - {Message}", 
                userId, subject, message);
                
            await Task.CompletedTask;
        }
    }
} 