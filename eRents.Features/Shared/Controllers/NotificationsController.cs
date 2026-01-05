using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using Microsoft.AspNetCore.Authorization;
using eRents.Features.Shared.Services;
using eRents.Domain.Shared.Interfaces;
using Microsoft.Extensions.Logging;
// NOTE: Do not reference WebApi from Features to avoid circular dependencies

namespace eRents.Features.Shared.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class NotificationsController : ControllerBase
    {
        private readonly INotificationService _notificationService;
        private readonly ICurrentUserService _currentUserService;
        private readonly ILogger<NotificationsController> _logger;

        public NotificationsController(
            INotificationService notificationService,
            ICurrentUserService currentUserService,
            ILogger<NotificationsController> logger)
        {
            _notificationService = notificationService;
            _currentUserService = currentUserService;
            _logger = logger;
        }

        #region User Notification Endpoints

        /// <summary>
        /// Get notifications for the current user (paginated)
        /// </summary>
        [HttpGet("my")]
        [Authorize]
        public async Task<IActionResult> GetMyNotifications([FromQuery] int skip = 0, [FromQuery] int take = 20)
        {
            var userId = _currentUserService.GetUserIdAsInt();
            if (!userId.HasValue)
                return Unauthorized();

            try
            {
                var notifications = await _notificationService.GetNotificationsAsync(userId.Value, skip, take);
                return Ok(notifications);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting notifications for user {UserId}", userId.Value);
                return StatusCode(500, "Internal server error");
            }
        }

        /// <summary>
        /// Get unread notifications for the current user
        /// </summary>
        [HttpGet("my/unread")]
        [Authorize]
        public async Task<IActionResult> GetMyUnreadNotifications()
        {
            var userId = _currentUserService.GetUserIdAsInt();
            if (!userId.HasValue)
                return Unauthorized();

            try
            {
                var notifications = await _notificationService.GetUnreadNotificationsAsync(userId.Value);
                return Ok(notifications);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting unread notifications for user {UserId}", userId.Value);
                return StatusCode(500, "Internal server error");
            }
        }

        /// <summary>
        /// Get unread notification count for the current user
        /// </summary>
        [HttpGet("my/count")]
        [Authorize]
        public async Task<IActionResult> GetMyUnreadCount()
        {
            var userId = _currentUserService.GetUserIdAsInt();
            if (!userId.HasValue)
                return Unauthorized();

            try
            {
                var count = await _notificationService.GetUnreadCountAsync(userId.Value);
                return Ok(new { unreadCount = count });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting unread count for user {UserId}", userId.Value);
                return StatusCode(500, "Internal server error");
            }
        }

        /// <summary>
        /// Mark a notification as read
        /// </summary>
        [HttpPut("{id}/read")]
        [Authorize]
        public async Task<IActionResult> MarkAsRead(int id)
        {
            try
            {
                await _notificationService.MarkAsReadAsync(id);
                return Ok();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error marking notification {Id} as read", id);
                return StatusCode(500, "Internal server error");
            }
        }

        /// <summary>
        /// Mark all notifications as read for current user
        /// </summary>
        [HttpPut("my/read-all")]
        [Authorize]
        public async Task<IActionResult> MarkAllAsRead()
        {
            var userId = _currentUserService.GetUserIdAsInt();
            if (!userId.HasValue)
                return Unauthorized();

            try
            {
                await _notificationService.MarkAllAsReadAsync(userId.Value);
                return Ok();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error marking all notifications as read for user {UserId}", userId.Value);
                return StatusCode(500, "Internal server error");
            }
        }

        /// <summary>
        /// Delete a notification
        /// </summary>
        [HttpDelete("{id}")]
        [Authorize]
        public async Task<IActionResult> DeleteNotification(int id)
        {
            try
            {
                await _notificationService.DeleteNotificationAsync(id);
                return Ok();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting notification {Id}", id);
                return StatusCode(500, "Internal server error");
            }
        }

        #endregion

        #region Internal Notification Creation Endpoints (for backend services)

        [HttpPost("message")]
        public async Task<IActionResult> SendMessageNotification([FromBody] MessageNotification notification)
        {
            try
            {
                await _notificationService.CreateNotificationAsync(
                    notification.ReceiverId, 
                    "New Message", 
                    notification.Message, 
                    "message", 
                    notification.SenderId);

                // Real-time broadcast is handled in WebApi layer to avoid dependency here

                _logger.LogInformation("Message notification sent to user {ReceiverId}", notification.ReceiverId);
                return Ok();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error sending message notification");
                return StatusCode(500, "Internal server error");
            }
        }

        [HttpPost("booking")]
        public async Task<IActionResult> SendBookingNotification([FromBody] BookingNotification notification)
        {
            try
            {
                await _notificationService.CreateBookingNotificationAsync(notification.UserId, notification.BookingId, "Booking Update", notification.Notification);
                // Real-time broadcast is handled in WebApi layer to avoid dependency here

                _logger.LogInformation("Booking notification sent to user {UserId}", notification.UserId);
                return Ok();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error sending booking notification");
                return StatusCode(500, "Internal server error");
            }
        }

        [HttpPost("review")]
        public async Task<IActionResult> SendReviewNotification([FromBody] ReviewNotification notification)
        {
            try
            {
                await _notificationService.CreateReviewNotificationAsync(notification.PropertyOwnerId, notification.ReviewId, "New Review", notification.Notification);
                // Real-time broadcast is handled in WebApi layer to avoid dependency here

                _logger.LogInformation("Review notification sent to property owner {PropertyOwnerId}", notification.PropertyOwnerId);
                return Ok();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error sending review notification");
                return StatusCode(500, "Internal server error");
            }
        }

        [HttpPost("system")]
        public async Task<IActionResult> SendSystemNotification([FromBody] SystemNotification notification)
        {
            try
            {
                await _notificationService.CreateSystemNotificationAsync(notification.UserId, "System Notification", notification.Notification);
                // Real-time broadcast is handled in WebApi layer to avoid dependency here

                return Ok();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error sending system notification");
                return StatusCode(500, "Internal server error");
            }
        }

        #endregion
    }

    // Notification DTOs
    public class MessageNotification
    {
        public int SenderId { get; set; }
        public int ReceiverId { get; set; }
        public string Message { get; set; } = string.Empty;
        public DateTime Timestamp { get; set; }
    }

    public class BookingNotification
    {
        public int UserId { get; set; }
        public int BookingId { get; set; }
        public string Notification { get; set; } = string.Empty;
        public DateTime Timestamp { get; set; }
    }

    public class ReviewNotification
    {
        public int PropertyOwnerId { get; set; }
        public int ReviewId { get; set; }
        public string Notification { get; set; } = string.Empty;
        public DateTime Timestamp { get; set; }
    }

    public class SystemNotification
    {
        public int UserId { get; set; }
        public string Notification { get; set; } = string.Empty;
        public DateTime Timestamp { get; set; }
    }
} 