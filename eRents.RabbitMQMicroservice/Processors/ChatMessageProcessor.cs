using eRents.RabbitMQMicroservice.Services;
using eRents.Shared.DTOs;
using Newtonsoft.Json;
using RabbitMQ.Client.Events;
using System.Text;

namespace eRents.RabbitMQMicroservice.Processors
{
	public class ChatMessageProcessor
	{
		private readonly IMessageService _messageService;

		public ChatMessageProcessor(IMessageService messageService)
		{
			_messageService = messageService;
		}

		public void Process(object sender, BasicDeliverEventArgs e)
		{
			var body = e.Body.ToArray();
			var messageJson = Encoding.UTF8.GetString(body);
			var userMessage = JsonConvert.DeserializeObject<UserMessage>(messageJson);

			if (userMessage != null)
			{
				_messageService.HandleUserMessage(userMessage);
				Console.WriteLine($"Processed chat message from {userMessage.SenderUsername} to {userMessage.RecipientUsername}");
			}
		}
	}
}
