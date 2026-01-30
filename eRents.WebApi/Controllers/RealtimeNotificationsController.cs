using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using Microsoft.Extensions.Configuration;
using eRents.WebApi.Hubs;
using eRents.Features.Shared.Controllers;
using System;
using System.Linq;

namespace eRents.WebApi.Controllers
{
    [ApiController]
    [AllowAnonymous]
    [Route("api/realtime/notifications")]
    public class RealtimeNotificationsController : ControllerBase
    {
        private readonly IHubContext<ChatHub> _hubContext;
        private readonly IConfiguration _configuration;

        public RealtimeNotificationsController(IHubContext<ChatHub> hubContext, IConfiguration configuration)
        {
            _hubContext = hubContext;
            _configuration = configuration;
        }

        private bool IsAuthorizedRequest()
        {
            if (User?.Identity?.IsAuthenticated == true)
            {
                return true;
            }

            var expectedKey = _configuration["InternalApi:Key"];
            if (string.IsNullOrWhiteSpace(expectedKey))
            {
                return false;
            }

            var providedKey = Request.Headers["X-Internal-Api-Key"].FirstOrDefault();
            return string.Equals(providedKey, expectedKey, StringComparison.Ordinal);
        }

        [HttpPost("message")]
        public async Task<IActionResult> SendMessage([FromBody] MessageNotification notification)
        {
            if (!IsAuthorizedRequest()) return Unauthorized();

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
            if (!IsAuthorizedRequest()) return Unauthorized();

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
            if (!IsAuthorizedRequest()) return Unauthorized();

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
            if (!IsAuthorizedRequest()) return Unauthorized();

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
