using eRents.Shared.DTOs;

namespace eRents.RabbitMQMicroservice.Services
{
	public interface IMessageService
	{
		void HandleUserMessage(UserMessage message);
	}
}
