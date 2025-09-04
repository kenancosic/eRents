using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using eRents.Features.Shared.Services;
using Microsoft.Extensions.Logging;

namespace eRents.Features.Shared.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class NotificationsController : ControllerBase
    {
        private readonly INotificationService _notificationService;
        private readonly ILogger<NotificationsController> _logger;

        public NotificationsController(
            INotificationService notificationService,
            ILogger<NotificationsController> logger)
        {
            _notificationService = notificationService;
            _logger = logger;
        }

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
                return Ok();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error sending system notification");
                return StatusCode(500, "Internal server error");
            }
        }
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