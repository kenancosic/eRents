using AutoMapper;
using eRents.Domain.Models;
using eRents.Domain.Repositories;
using eRents.Shared.Messaging;
using eRents.Shared.Services;

namespace eRents.Application.Service.MessagingService
{
	public class MessageHandlerService : IMessageHandlerService
	{
		private readonly IUserRepository _userRepository;
		private readonly IMessageRepository _messageRepository;
		private readonly IMapper _mapper;

		public MessageHandlerService(IUserRepository userRepository, IMessageRepository messageRepository, IMapper mapper)
		{
			_userRepository = userRepository;
			_messageRepository = messageRepository;
			_mapper = mapper;
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
			// Handle the special case where username is in format "user_{id}"
			if (username.StartsWith("user_") && int.TryParse(username.Substring(5), out var userId))
			{
				return userId;
			}

			var user = await _userRepository.GetByUsernameAsync(username);
			return user?.UserId ?? 0;
		}

		public async Task<string> GetUsernameByUserIdAsync(int userId)
		{
			var user = await _userRepository.GetByIdAsync(userId);
			return user?.Username ?? $"user_{userId}";
		}
	}
}
