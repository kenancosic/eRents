using eRents.Shared.DTO;

namespace eRents.Application.Service.MessagingService
{
	public interface IMessageHandlerService
	{
		Task HandleUserMessageAsync(UserMessage message);
		Task SendMessageAsync(UserMessage userMessage);
		Task<IEnumerable<UserMessage>> GetMessagesAsync(int senderId, int receiverId);
		Task MarkMessageAsReadAsync(int messageId);
	}
}