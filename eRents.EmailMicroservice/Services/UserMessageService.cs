using eRents.RabbitMQMicroservice.DTO;

namespace eRents.RabbitMQMicroservice.Services
{
	public class UserMessageService : IMessageService
	{
		public void HandleUserMessage(UserMessage message)
		{
			// Implement your user messaging logic here (e.g., storing in database, notifying users, etc.)
			Console.WriteLine($"Processing message from {message.SenderEmail} to {message.RecipientEmail}");
		}
	}
}