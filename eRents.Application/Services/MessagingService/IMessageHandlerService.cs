using eRents.Shared.Messaging;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;

namespace eRents.Application.Services.MessagingService
{
	public interface IMessageHandlerService
	{
		Task HandleUserMessageAsync(UserMessage message);
		Task SendMessageAsync(UserMessage userMessage);
		Task<IEnumerable<UserMessage>> GetMessagesAsync(int senderId, int receiverId);
		Task MarkMessageAsReadAsync(int messageId);
		Task<int> GetUserIdByUsernameAsync(string username);
		Task<string> GetUsernameByUserIdAsync(int userId);
		
		// HTTP API methods with RabbitMQ + SignalR
		Task<MessageResponse> SendMessageAsync(int senderId, SendMessageRequest request);
		Task<IEnumerable<MessageResponse>> GetConversationAsync(int userId, int contactId);
		Task<IEnumerable<UserResponse>> GetContactsAsync(int userId);
		Task SendMessageToUserAsync(int receiverId, string eventName, object data);
		Task<MessageResponse> SendPropertyOfferMessageAsync(int senderId, int receiverId, int propertyId);
	}
}