using eRents.Domain.Models;
using eRents.Domain.Shared;
using eRents.Features.Core.Models.Shared;
using eRents.Shared.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.AspNetCore.SignalR;
using eRents.Shared.DTOs;
using eRents.Domain.Shared.Interfaces;

namespace eRents.Features.Shared.Services
{
	/// <summary>
	/// Consolidated messaging service using direct ERentsContext access
	/// Combines MessageHandler, RealTime, and UserLookup functionality
	/// Integrates with both RabbitMQ and SignalR for complete messaging solution
	/// </summary>
	public class MessagingService : IMessagingService
	{
		private readonly ERentsContext _context;
		private readonly ICurrentUserService _currentUserService;
		private readonly ILogger<MessagingService> _logger;
		private readonly IRabbitMQService? _rabbitMqService;
		private readonly IHubContext<Hub>? _hubContext;

		public MessagingService(
						ERentsContext context,
						ICurrentUserService currentUserService,
						ILogger<MessagingService> logger,
						IRabbitMQService? rabbitMqService = null,
						IHubContext<Hub>? hubContext = null)
		{
			_context = context;
			_currentUserService = currentUserService;
			_logger = logger;
			_rabbitMqService = rabbitMqService;
			_hubContext = hubContext;
		}

		#region Core Messaging Operations

		public async Task<MessageResponse> SendMessageAsync(int senderId, SendMessageRequest request)
		{
			try
			{
				// Business validation
				if (string.IsNullOrWhiteSpace(request.MessageText))
					throw new ArgumentException("Message cannot be empty");

				if (senderId == request.ReceiverId)
					throw new ArgumentException("Cannot send message to yourself");

				// Verify users exist
				var sender = await _context.Users
						.FirstOrDefaultAsync(u => u.UserId == senderId);
				var receiver = await _context.Users
						.FirstOrDefaultAsync(u => u.UserId == request.ReceiverId);

				if (sender == null)
					throw new ArgumentException("Sender not found");
				if (receiver == null)
					throw new ArgumentException("Receiver not found");

				// Create message entity - audit fields are set by SaveChangesAsync
				var messageEntity = new Message
				{
					SenderId = senderId,
					ReceiverId = request.ReceiverId,
					MessageText = request.MessageText,
					IsRead = false,
					IsDeleted = false
				};

				_context.Messages.Add(messageEntity);
				await _context.SaveChangesAsync();

				// Send via RabbitMQ for reliable processing (if available)
				if (_rabbitMqService != null)
				{
					var senderUsername = sender.Username ?? $"user_{senderId}";
					var receiverUsername = receiver.Username ?? $"user_{request.ReceiverId}";

					var userMessage = new UserMessage
					{
						SenderUsername = senderUsername,
						RecipientUsername = receiverUsername,
						Subject = "Chat Message",
						Body = request.MessageText
					};

					await _rabbitMqService.PublishMessageAsync(userMessage, "messageQueue");
				}

				// Send via SignalR for real-time notification
				if (_hubContext != null)
				{
					await SendRealTimeMessageAsync(senderId, request.ReceiverId, request.MessageText, messageEntity.CreatedAt);
				}

				_logger.LogInformation("Message sent from User {SenderId} to User {ReceiverId}",
						senderId, request.ReceiverId);

				return new MessageResponse
				{
					Id = messageEntity.MessageId,
					SenderId = senderId,
					ReceiverId = request.ReceiverId,
					MessageText = request.MessageText,
					CreatedAt = messageEntity.CreatedAt,
					IsRead = messageEntity.IsRead ?? false,
					IsDeleted = messageEntity.IsDeleted,
					SenderName = $"{sender.FirstName} {sender.LastName}",
					ReceiverName = $"{receiver.FirstName} {receiver.LastName}"
				};
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error sending message from User {SenderId} to User {ReceiverId}",
						senderId, request.ReceiverId);
				throw;
			}
		}

		public async Task<IEnumerable<MessageResponse>> GetConversationAsync(int userId, int contactId)
		{
			try
			{
				var messages = await _context.Messages
						.Where(m => (m.SenderId == userId && m.ReceiverId == contactId) ||
											 (m.SenderId == contactId && m.ReceiverId == userId))
						.Where(m => !m.IsDeleted)
						.OrderBy(m => m.CreatedAt)
						.ToListAsync();

				// Get user details for mapping
				var userIds = messages.Select(m => m.SenderId)
						.Union(messages.Select(m => m.ReceiverId))
						.Distinct()
						.ToList();

				var users = await _context.Users
						.Where(u => userIds.Contains(u.UserId))
						.ToDictionaryAsync(u => u.UserId, u => u);

				return messages.Select(m => new MessageResponse
				{
					Id = m.MessageId,
					SenderId = m.SenderId,
					ReceiverId = m.ReceiverId,
					MessageText = m.MessageText,
					CreatedAt = m.CreatedAt,
					IsRead = m.IsRead ?? false,
					IsDeleted = m.IsDeleted,
					SenderName = users.GetValueOrDefault(m.SenderId)?.FirstName + " " +
												users.GetValueOrDefault(m.SenderId)?.LastName ?? "Unknown",
					ReceiverName = users.GetValueOrDefault(m.ReceiverId)?.FirstName + " " +
													users.GetValueOrDefault(m.ReceiverId)?.LastName ?? "Unknown"
				});
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error getting conversation between User {UserId} and User {ContactId}",
						userId, contactId);
				throw;
			}
		}

		public async Task<IEnumerable<object>> GetContactsAsync(int userId)
		{
			try
			{
				// Get all users except the current user
				var contacts = await _context.Users
						.Where(u => u.UserId != userId)
						.Select(u => new
						{
							Id = u.UserId,
							FirstName = u.FirstName,
							LastName = u.LastName,
							Email = u.Email,
							Username = u.Username,
							ProfileImageId = u.ProfileImageId
						})
						.Cast<object>()
						.ToListAsync();

				return contacts;
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error getting contacts for User {UserId}", userId);
				throw;
			}
		}

		public async Task MarkMessageAsReadAsync(int messageId)
		{
			try
			{
				var message = await _context.Messages
						.FirstOrDefaultAsync(m => m.MessageId == messageId);

				if (message != null)
				{
					message.IsRead = true;
					await _context.SaveChangesAsync();

					_logger.LogInformation("Message {MessageId} marked as read", messageId);
				}
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error marking message {MessageId} as read", messageId);
				throw;
			}
		}

		public async Task<bool> SendPropertyOfferMessageAsync(int senderId, int receiverId, int propertyId, string offerMessage)
		{
			try
			{
				var request = new SendMessageRequest
				{
					ReceiverId = receiverId,
					MessageText = offerMessage
				};

				var result = await SendMessageAsync(senderId, request);

				return result != null;
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error sending custom property offer message for Property {PropertyId}", propertyId);
				return false;
			}
		}

		public async Task<MessageResponse> SendPropertyOfferMessageAsync(int senderId, int receiverId, int propertyId)
		{
			try
			{
				// Get property details for the message
				var property = await _context.Properties
						.FirstOrDefaultAsync(p => p.PropertyId == propertyId);

				if (property == null)
					throw new ArgumentException("Property not found");

				var messageText = $"I'm interested in your property: {property.Name}. " +
												 $"Could we discuss rental terms?";

				var request = new SendMessageRequest
				{
					ReceiverId = receiverId,
					MessageText = messageText
				};

				return await SendMessageAsync(senderId, request);
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error sending property offer message for Property {PropertyId}", propertyId);
				throw;
			}
		}

		#endregion

		#region Helper Methods

		/// <summary>
		/// Get username by user ID for messaging operations
		/// </summary>
		private async Task<string> GetUsernameByUserIdAsync(int userId)
		{
			try
			{
				var user = await _context.Users
						.Where(u => u.UserId == userId)
						.Select(u => u.Username)
						.FirstOrDefaultAsync();

				return user ?? $"user_{userId}";
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error getting username for User {UserId}", userId);
				return $"user_{userId}";
			}
		}

		#endregion

		#region Real-Time Operations

		public async Task SendRealTimeMessageAsync(int senderId, int receiverId, string messageText, DateTime createdAt)
		{
			try
			{
				if (_hubContext == null)
				{
					_logger.LogWarning("SignalR hub context not available for real-time messaging");
					return;
				}

				// Get sender details
				var senderName = await GetUsernameByUserIdAsync(senderId);

				var messageData = new
				{
					senderId,
					senderName,
					receiverId,
					messageText,
					CreatedAt = createdAt,
					IsRead = false
				};

				// Send to receiver if online
				await _hubContext.Clients.Group($"user-{receiverId}")
						.SendAsync("ReceiveMessage", messageData);

				_logger.LogInformation("Real-time message sent from User {SenderId} to User {ReceiverId}",
						senderId, receiverId);
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error sending real-time message from User {SenderId} to User {ReceiverId}",
						senderId, receiverId);
			}
		}

		public async Task SendSystemNotificationAsync(int userId, string notification)
		{
			try
			{
				if (_hubContext == null)
				{
					_logger.LogWarning("SignalR hub context not available for system notifications");
					return;
				}

				await _hubContext.Clients.Group($"user-{userId}")
						.SendAsync("SystemNotification", new
						{
							message = notification,
							timestamp = DateTime.UtcNow
						});

				_logger.LogInformation("System notification sent to User {UserId}: {Notification}",
						userId, notification);
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
				if (_hubContext == null)
				{
					_logger.LogWarning("SignalR hub context not available for user status broadcast");
					return;
				}

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

		public async Task SendMessageToUserAsync(int receiverId, string eventName, object data)
		{
			try
			{
				if (_hubContext == null)
				{
					_logger.LogWarning("SignalR hub context not available for custom events");
					return;
				}

				await _hubContext.Clients.Group($"user-{receiverId}")
						.SendAsync(eventName, data);

				_logger.LogInformation("Custom event {EventName} sent to User {ReceiverId}",
						eventName, receiverId);
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error sending custom event {EventName} to User {ReceiverId}",
						eventName, receiverId);
			}
		}

		#endregion


	}
}