using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using eRents.WebApi.Hubs;
using eRents.Features.Shared.Controllers;

namespace eRents.WebApi.Controllers
{
    [ApiController]
    [Authorize]
    [Route("api/realtime/notifications")]
    public class RealtimeNotificationsController : ControllerBase
    {
        private readonly IHubContext<ChatHub> _hubContext;

        public RealtimeNotificationsController(IHubContext<ChatHub> hubContext)
        {
            _hubContext = hubContext;
        }

        [HttpPost("message")]
        public async Task<IActionResult> SendMessage([FromBody] MessageNotification notification)
        {
            await _hubContext.Clients.Group($"user-{notification.ReceiverId}")
                .SendAsync("ReceiveNotification", new
                {
                    type = "message",
                    title = "New Message",
                    message = notification.Message,
                    referenceId = notification.SenderId,
                    timestamp = DateTime.UtcNow
                });
            return Ok();
        }

        [HttpPost("booking")]
        public async Task<IActionResult> SendBooking([FromBody] BookingNotification notification)
        {
            await _hubContext.Clients.Group($"user-{notification.UserId}")
                .SendAsync("ReceiveNotification", new
                {
                    type = "booking",
                    title = "Booking Update",
                    message = notification.Notification,
                    referenceId = notification.BookingId,
                    timestamp = DateTime.UtcNow
                });
            return Ok();
        }

        [HttpPost("review")]
        public async Task<IActionResult> SendReview([FromBody] ReviewNotification notification)
        {
            await _hubContext.Clients.Group($"user-{notification.PropertyOwnerId}")
                .SendAsync("ReceiveNotification", new
                {
                    type = "review",
                    title = "New Review",
                    message = notification.Notification,
                    referenceId = notification.ReviewId,
                    timestamp = DateTime.UtcNow
                });
            return Ok();
        }

        [HttpPost("system")]
        public async Task<IActionResult> SendSystem([FromBody] SystemNotification notification)
        {
            await _hubContext.Clients.Group($"user-{notification.UserId}")
                .SendAsync("ReceiveNotification", new
                {
                    type = "system",
                    title = "System Notification",
                    message = notification.Notification,
                    timestamp = DateTime.UtcNow
                });
            return Ok();
        }
    }
}
