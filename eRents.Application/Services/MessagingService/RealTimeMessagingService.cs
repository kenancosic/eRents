using eRents.Shared.Messaging;
using eRents.Shared.Services;
using Microsoft.AspNetCore.SignalR;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;

namespace eRents.Application.Services.MessagingService
{
	public interface IRealTimeMessagingService
	{
		Task SendMessageAsync(int senderId, int receiverId, string messageText);
		Task SendSystemNotificationAsync(int userId, string notification);
		Task BroadcastUserStatusAsync(int userId, bool isOnline);
	}

	public class RealTimeMessagingService<TChatHub> : IRealTimeMessagingService where TChatHub : Hub
	{
		private readonly IHubContext<TChatHub> _hubContext;
		private readonly IUserLookupService _userLookupService;
		private readonly IRabbitMQService _rabbitMqService;
		private readonly ILogger<RealTimeMessagingService<TChatHub>> _logger;

		public RealTimeMessagingService(
				IHubContext<TChatHub> hubContext,
				IUserLookupService userLookupService,
				IRabbitMQService rabbitMqService,
				ILogger<RealTimeMessagingService<TChatHub>> logger)
		{
			_hubContext = hubContext;
			_userLookupService = userLookupService;
			_rabbitMqService = rabbitMqService;
			_logger = logger;
		}

		public async Task SendMessageAsync(int senderId, int receiverId, string messageText)
		{
			try
			{
				// Get usernames for the message
				var senderUsername = await _userLookupService.GetUsernameByUserIdAsync(senderId);
				var receiverUsername = await _userLookupService.GetUsernameByUserIdAsync(receiverId);

				// Create and save the message
				var userMessage = new UserMessage
				{
					SenderUsername = senderUsername,
					RecipientUsername = receiverUsername,
					Subject = "Chat Message",
					Body = messageText
				};

				// Send to RabbitMQ for processing
				await _rabbitMqService.PublishMessageAsync("messageQueue", userMessage);

				// Send real-time notification via SignalR
				var messageData = new
				{
					senderId,
					senderName = senderUsername,
					receiverId,
					messageText,
					dateSent = DateTime.UtcNow,
					isRead = false
				};

				// Send to receiver if online
				await _hubContext.Clients.Group($"user-{receiverId}").SendAsync("ReceiveMessage", messageData);

				_logger.LogInformation("Message sent from User {SenderId} to User {ReceiverId} via real-time service",
						senderId, receiverId);
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error sending real-time message from User {SenderId} to User {ReceiverId}",
						senderId, receiverId);
				throw;
			}
		}

		public async Task SendSystemNotificationAsync(int userId, string notification)
		{
			try
			{
				await _hubContext.Clients.Group($"user-{userId}").SendAsync("SystemNotification", new
				{
					message = notification,
					timestamp = DateTime.UtcNow
				});

				_logger.LogInformation("System notification sent to User {UserId}", userId);
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error sending system notification to User {UserId}", userId);
			}
		}

		public async Task BroadcastUserStatusAsync(int userId, bool isOnline)
		{
			try
			{
				await _hubContext.Clients.All.SendAsync("UserStatusChanged", new
				{
					userId,
					isOnline,
					timestamp = DateTime.UtcNow
				});

				_logger.LogInformation("User {UserId} status broadcasted: {Status}",
						userId, isOnline ? "Online" : "Offline");
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error broadcasting user status for User {UserId}", userId);
			}
		}
	}
}