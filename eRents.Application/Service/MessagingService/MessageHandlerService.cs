using AutoMapper;
using eRents.Domain.Models;
using eRents.Domain.Repositories;
using eRents.Shared.DTO;

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

			if (sender == null || sender == null)
			{
				throw new ArgumentException("Sender or Recipient username is invalid.");
			}

			var messageEntity = new Message
			{
				SenderId = sender.UserId,
				ReceiverId = sender.UserId,
				MessageText = message.Body,
				DateSent = DateTime.UtcNow,
				IsRead = false
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
	}
}
