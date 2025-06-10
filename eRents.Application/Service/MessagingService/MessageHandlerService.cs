using AutoMapper;
using eRents.Domain.Models;
using eRents.Domain.Repositories;
using eRents.Shared.Messaging;
using eRents.Shared.Services;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;

namespace eRents.Application.Service.MessagingService
{
	public class MessageHandlerService : IMessageHandlerService
	{
		private readonly IUserRepository _userRepository;
		private readonly IMessageRepository _messageRepository;
		private readonly IMapper _mapper;
		private readonly IRealTimeMessagingService _realTimeMessagingService;
		private readonly IRabbitMQService _rabbitMqService;
		private readonly IUserLookupService _userLookupService;

		public MessageHandlerService(
			IUserRepository userRepository, 
			IMessageRepository messageRepository, 
			IMapper mapper,
			IRealTimeMessagingService realTimeMessagingService,
			IRabbitMQService rabbitMqService,
			IUserLookupService userLookupService)
		{
			_userRepository = userRepository;
			_messageRepository = messageRepository;
			_mapper = mapper;
			_realTimeMessagingService = realTimeMessagingService;
			_rabbitMqService = rabbitMqService;
			_userLookupService = userLookupService;
		}

		public async Task HandleUserMessageAsync(UserMessage message)
		{
			var sender = await _userRepository.GetByUsernameAsync(message.SenderUsername);
			var recipient = await _userRepository.GetByUsernameAsync(message.RecipientUsername);

			if (sender == null || recipient == null)
			{
				throw new ArgumentException("Sender or Recipient username is invalid.");
			}

			var messageEntity = new Message
			{
				SenderId = sender.UserId,
				ReceiverId = recipient.UserId,
				MessageText = message.Body,
				DateSent = DateTime.UtcNow,
				IsRead = false,
				CreatedBy = sender.UserId.ToString(),
				ModifiedBy = sender.UserId.ToString()
			};

			await _messageRepository.AddAsync(messageEntity);
		}

		public async Task SendMessageAsync(UserMessage userMessage)
		{
			await HandleUserMessageAsync(userMessage);
		}

		public async Task<IEnumerable<UserMessage>> GetMessagesAsync(int senderId, int receiverId)
		{
			var messages = await _messageRepository.GetMessagesBetweenUsersAsync(senderId, receiverId);
			return _mapper.Map<IEnumerable<UserMessage>>(messages);
		}

		public async Task MarkMessageAsReadAsync(int messageId)
		{
			await _messageRepository.MarkMessageAsReadAsync(messageId);
		}

		public async Task<int> GetUserIdByUsernameAsync(string username)
		{
			return await _userLookupService.GetUserIdByUsernameAsync(username);
		}

		public async Task<string> GetUsernameByUserIdAsync(int userId)
		{
			return await _userLookupService.GetUsernameByUserIdAsync(userId);
		}

		// HTTP API methods - Application layer business logic with RabbitMQ + SignalR
		public async Task<MessageResponse> SendMessageAsync(int senderId, SendMessageRequest request)
		{
			// Business validation
			if (string.IsNullOrWhiteSpace(request.MessageText))
				throw new ArgumentException("Message cannot be empty");

			if (senderId == request.ReceiverId)
				throw new ArgumentException("Cannot send message to yourself");

			// Verify users exist
			var sender = await _userRepository.GetByIdAsync(senderId);
			var receiver = await _userRepository.GetByIdAsync(request.ReceiverId);

			if (sender == null)
				throw new ArgumentException("Sender not found");
			if (receiver == null)
				throw new ArgumentException("Receiver not found");

			// Get usernames for RabbitMQ
			var senderUsername = sender.Username ?? $"user_{senderId}";
			var receiverUsername = receiver.Username ?? $"user_{request.ReceiverId}";

			// Create UserMessage for RabbitMQ reliable processing
			var userMessage = new UserMessage
			{
				SenderUsername = senderUsername,
				RecipientUsername = receiverUsername,
				Subject = "Chat Message",
				Body = request.MessageText
			};

			// Send to RabbitMQ for guaranteed processing and persistence
			await _rabbitMqService.PublishMessageAsync("messageQueue", userMessage);

			// Immediate SignalR notification for real-time experience
			await _realTimeMessagingService.SendMessageAsync(senderId, request.ReceiverId, request.MessageText);

			// Return response (the message will be persisted by the RabbitMQ microservice)
			return new MessageResponse
			{
				Id = 0, // Will be set when the microservice processes the message
				SenderId = senderId,
				ReceiverId = request.ReceiverId,
				MessageText = request.MessageText,
				DateSent = DateTime.UtcNow,
				IsRead = false,
				IsDeleted = false,
				SenderName = $"{sender.FirstName} {sender.LastName}",
				ReceiverName = $"{receiver.FirstName} {receiver.LastName}"
			};
		}

		public async Task<IEnumerable<MessageResponse>> GetConversationAsync(int userId, int contactId)
		{
			var messages = await _messageRepository.GetMessagesBetweenUsersAsync(userId, contactId);
			
			// Get user details individually - simpler approach
			var userCache = new Dictionary<int, User>();
			
			foreach (var message in messages)
			{
				if (!userCache.ContainsKey(message.SenderId))
				{
					var sender = await _userRepository.GetByIdAsync(message.SenderId);
					if (sender != null) userCache[message.SenderId] = sender;
				}
				if (!userCache.ContainsKey(message.ReceiverId))
				{
					var receiver = await _userRepository.GetByIdAsync(message.ReceiverId);
					if (receiver != null) userCache[message.ReceiverId] = receiver;
				}
			}

			return messages.Select(m => new MessageResponse
			{
				Id = m.MessageId,
				SenderId = m.SenderId,
				ReceiverId = m.ReceiverId,
				MessageText = m.MessageText,
				DateSent = m.DateSent ?? DateTime.UtcNow,
				IsRead = m.IsRead ?? false,
				IsDeleted = m.IsDeleted,
				SenderName = userCache.GetValueOrDefault(m.SenderId)?.FirstName + " " + userCache.GetValueOrDefault(m.SenderId)?.LastName ?? "Unknown",
				ReceiverName = userCache.GetValueOrDefault(m.ReceiverId)?.FirstName + " " + userCache.GetValueOrDefault(m.ReceiverId)?.LastName ?? "Unknown"
			});
		}

		public async Task<IEnumerable<UserResponse>> GetContactsAsync(int userId)
		{
			// Get all users except the current user - simplified for now
			var allUsers = _userRepository.GetQueryable().Where(u => u.UserId != userId).ToList();

			return allUsers.Select(c => new UserResponse
			{
				Id = c.UserId,
				FirstName = c.FirstName,
				LastName = c.LastName,
				Email = c.Email,
				Username = c.Username,
				FullName = $"{c.FirstName} {c.LastName}",
				Role = c.UserTypeNavigation?.TypeName ?? "Unknown",
				ProfileImageId = c.ProfileImageId
			});
		}



		public async Task SendMessageToUserAsync(int receiverId, string eventName, object data)
		{
			// Send via SignalR directly for immediate notification
			await _realTimeMessagingService.SendSystemNotificationAsync(receiverId, 
				$"{eventName}: {System.Text.Json.JsonSerializer.Serialize(data)}");
		}

		public async Task<MessageResponse> SendPropertyOfferMessageAsync(int senderId, int receiverId, int propertyId)
		{
			var request = new SendMessageRequest
			{
				ReceiverId = receiverId,
				MessageText = $"PROPERTY_OFFER::{propertyId}"
			};

			// Use standard messaging with RabbitMQ + SignalR for property offers
			return await SendMessageAsync(senderId, request);
		}
	}
}
