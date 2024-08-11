using eRents.RabbitMQMicroservice.Services;
using eRents.Shared.DTO;
using Newtonsoft.Json;

namespace eRents.RabbitMQMicroservice.Processors
{
	public class MessageProcessor
	{
		private readonly IMessageService _messageService;

		public MessageProcessor(IMessageService messageService)
		{
			_messageService = messageService;
		}

		public void Process(string message)
		{
			var userMessage = JsonConvert.DeserializeObject<UserMessage>(message);
			_messageService.HandleUserMessage(userMessage);
		}
	}
}
