using eRents.Shared.Messaging;

namespace eRents.RabbitMQMicroservice.Services
{
	public class UserMessageService : IMessageService
	{
		public void HandleUserMessage(UserMessage message)
		{
			Console.WriteLine($"Handling message from {message.SenderUsername} to {message.RecipientUsername}: {message.Subject}");
		}
	}
}
