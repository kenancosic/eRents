using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using eRents.WebApi.Hubs;
using eRents.Application.Service.MessagingService;
using Microsoft.Extensions.Logging;

namespace eRents.WebApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class NotificationsController : ControllerBase
    {
        private readonly IHubContext<ChatHub> _hubContext;
        private readonly IRealTimeMessagingService _realTimeMessagingService;
        private readonly ILogger<NotificationsController> _logger;

        public NotificationsController(
            IHubContext<ChatHub> hubContext,
            IRealTimeMessagingService realTimeMessagingService,
            ILogger<NotificationsController> logger)
        {
            _hubContext = hubContext;
            _realTimeMessagingService = realTimeMessagingService;
            _logger = logger;
        }

        [HttpPost("message")]
        public async Task<IActionResult> SendMessageNotification([FromBody] MessageNotification notification)
        {
            try
            {
                var messageData = new
                {
                    senderId = notification.SenderId,
                    receiverId = notification.ReceiverId,
                    message = notification.Message,
                    timestamp = notification.Timestamp
                };

                await _hubContext.Clients.Group($"user-{notification.ReceiverId}").SendAsync("ReceiveMessage", messageData);

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
                await _hubContext.Clients.Group($"user-{notification.UserId}").SendAsync("BookingNotification", notification);
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
                await _hubContext.Clients.Group($"user-{notification.PropertyOwnerId}").SendAsync("ReviewNotification", notification);
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
                await _realTimeMessagingService.SendSystemNotificationAsync(notification.UserId, notification.Notification);
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