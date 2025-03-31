using eRents.RabbitMQMicroservice.Processors;
using eRents.RabbitMQMicroservice.Services;
using Microsoft.Extensions.DependencyInjection;
using System.Text;

namespace eRents.RabbitMQMicroservice
{
	class Program
	{
		static void Main(string[] args)
		{
			var serviceProvider = new ServiceCollection()
					.AddTransient<IMessageService, UserMessageService>() // Microservice-specific message handling
					.AddTransient<ChatMessageProcessor>()
					.BuildServiceProvider();

			var rabbitMqService = new RabbitMQConsumerService();

			var chatMessageProcessor = serviceProvider.GetRequiredService<ChatMessageProcessor>();

			//Consume chat messages
			rabbitMqService.ConsumeMessages("messageQueue", (model, ea) =>
			{
				chatMessageProcessor.Process(model, ea);
			});

			Console.WriteLine(" [*] Waiting for messages.");
			Console.ReadLine();

			// Clean up
			rabbitMqService.Dispose();
		}
	}
}
