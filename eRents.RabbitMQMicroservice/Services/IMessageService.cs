using eRents.Shared.Messaging;

namespace eRents.RabbitMQMicroservice.Services
{
	public interface IMessageService
	{
		void HandleUserMessage(UserMessage message);
	}
}
