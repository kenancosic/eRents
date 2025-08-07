using Microsoft.AspNetCore.SignalR;
using Microsoft.AspNetCore.Authorization;
using eRents.Shared.Services;
using eRents.Features.Shared.Services;
using Microsoft.Extensions.Logging;
using System.Collections.Concurrent;
using eRents.Shared.DTOs;
using eRents.Domain.Shared.Interfaces;
using eRents.Features.Shared.DTOs;
using eRents.Features.Core.Models.Shared;

namespace eRents.WebApi.Hubs
{
	[Authorize]
	public class ChatHub : Hub
	{
		private readonly ILogger<ChatHub> _logger;
		private readonly ICurrentUserService _currentUserService;
		private readonly IMessagingService _messageHandlerService;

		// Track connected users: connectionId -> userId
		private static readonly ConcurrentDictionary<string, int> _connections = new();

		// Track user connections: userId -> list of connectionIds
		private static readonly ConcurrentDictionary<int, List<string>> _userConnections = new();

		public ChatHub(
				ILogger<ChatHub> logger,
				ICurrentUserService currentUserService,
				IMessagingService messageHandlerService)
		{
			_logger = logger;
			_currentUserService = currentUserService;
			_messageHandlerService = messageHandlerService;
		}

		public override async Task OnConnectedAsync()
		{
			if (!int.TryParse(_currentUserService.UserId, out var userId) || userId <= 0)
			{
				_logger.LogWarning("User connection rejected - invalid UserId: {UserId}", _currentUserService.UserId);
				return;
			}
			// Add connection to tracking
			_connections.TryAdd(Context.ConnectionId, userId);

			// Add to user connections
			_userConnections.AddOrUpdate(userId,
					new List<string> { Context.ConnectionId },
					(key, list) =>
					{
						list.Add(Context.ConnectionId);
						return list;
					});

			_logger.LogInformation("User {UserId} connected with ConnectionId {ConnectionId}",
					userId, Context.ConnectionId);

			// Join a group for this user
			await Groups.AddToGroupAsync(Context.ConnectionId, $"user-{userId}");

			// Notify the user they're connected
			await Clients.Caller.SendAsync("Connected", new { userId, connectionId = Context.ConnectionId });

			await base.OnConnectedAsync();
		}

		public override async Task OnDisconnectedAsync(Exception? exception)
		{
			if (_connections.TryRemove(Context.ConnectionId, out var userId))
			{
				// Remove from user connections
				if (_userConnections.TryGetValue(userId, out var connections))
				{
					connections.Remove(Context.ConnectionId);
					if (connections.Count == 0)
					{
						_userConnections.TryRemove(userId, out _);
					}
				}

				_logger.LogInformation("User {UserId} disconnected with ConnectionId {ConnectionId}",
						userId, Context.ConnectionId);

				// Remove from group
				await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"user-{userId}");
			}

			await base.OnDisconnectedAsync(exception);
		}

		/// <summary>
		/// Send a message to a specific user
		/// </summary>
		public async Task SendMessageToUser(int receiverId, string messageText)
		{
			try
			{
				if (!int.TryParse(_currentUserService.UserId, out var senderId) || senderId <= 0)
				{
					await Clients.Caller.SendAsync("Error", "User not authenticated");
					return;
				}

				var senderName = _currentUserService.GetUserClaims().FirstOrDefault(c => c.Type == System.Security.Claims.ClaimTypes.Name)?.Value ?? "Unknown User";

				_logger.LogInformation("User {SenderId} sending message to User {ReceiverId}",
						senderId, receiverId);

				// Create send message request
				SendMessageRequest sendMessageRequest = new SendMessageRequest
				{
					ReceiverId = receiverId,
					Subject = "Chat Message",
					Body = messageText,
					MessageText = messageText,
				};

				// Save message via service
				await _messageHandlerService.SendMessageAsync(senderId, sendMessageRequest);

				// Prepare message data for SignalR
				var messageData = new
				{
					senderId,
					senderName,
					receiverId,
					messageText,
					dateSent = DateTime.UtcNow,
					isRead = false
				};

				// Send to the receiver if online
				await Clients.Group($"user-{receiverId}").SendAsync("ReceiveMessage", messageData);

				// Send confirmation back to sender
				await Clients.Caller.SendAsync("MessageSent", messageData);

				_logger.LogInformation("Message sent successfully from User {SenderId} to User {ReceiverId}",
						senderId, receiverId);
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error sending message");
				await Clients.Caller.SendAsync("Error", $"Failed to send message: {ex.Message}");
			}
		}

		/// <summary>
		/// Mark a message as read
		/// </summary>
		public async Task MarkMessageAsRead(int messageId)
		{
			try
			{
				await _messageHandlerService.MarkMessageAsReadAsync(messageId);
				await Clients.Caller.SendAsync("MessageMarkedAsRead", messageId);

				_logger.LogInformation("Message {MessageId} marked as read by User {UserId}",
						messageId, _currentUserService.UserId);
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error marking message as read");
				await Clients.Caller.SendAsync("Error", $"Failed to mark message as read: {ex.Message}");
			}
		}

		/// <summary>
		/// Notify when user is typing
		/// </summary>
		public async Task UserTyping(int receiverId)
		{
			if (int.TryParse(_currentUserService.UserId, out var senderId) && senderId > 0)
			{
				var senderName = _currentUserService.GetUserClaims().FirstOrDefault(c => c.Type == System.Security.Claims.ClaimTypes.Name)?.Value ?? "Unknown User";
				await Clients.Group($"user-{receiverId}").SendAsync("UserTyping", new
				{
					userId = senderId,
					username = senderName
				});
			}
		}

		/// <summary>
		/// Notify when user stops typing
		/// </summary>
		public async Task UserStoppedTyping(int receiverId)
		{
			if (int.TryParse(_currentUserService.UserId, out var senderId) && senderId > 0)
			{
				await Clients.Group($"user-{receiverId}").SendAsync("UserStoppedTyping", new
				{
					userId = senderId
				});
			}
		}

		/// <summary>
		/// Get online status for a user
		/// </summary>
		public async Task GetUserOnlineStatus(int userId)
		{
			var isOnline = _userConnections.ContainsKey(userId);
			await Clients.Caller.SendAsync("UserOnlineStatus", new { userId, isOnline });
		}

		/// <summary>
		/// Get online status for multiple users
		/// </summary>
		public async Task GetUsersOnlineStatus(int[] userIds)
		{
			var statuses = userIds.Select(userId => new
			{
				userId,
				isOnline = _userConnections.ContainsKey(userId)
			}).ToList();

			await Clients.Caller.SendAsync("UsersOnlineStatus", statuses);
		}
	}
}