using eRents.RabbitMQMicroservice.DTO;

namespace eRents.RabbitMQMicroservice.Services
{
	public interface IMessageService
	{
		void HandleUserMessage(UserMessage message);
	}
}