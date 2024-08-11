using eRents.RabbitMQMicroservice.Processors;
using eRents.RabbitMQMicroservice.Services;
using eRents.Shared.Services;
using System.Text;

namespace eRents.RabbitMQMicroservice
{
	class Program
	{
		static void Main(string[] args)
		{
			var emailService = new SmtpEmailService();
			var messageService = new UserMessageService();

			var emailProcessor = new EmailProcessor(emailService);
			var messageProcessor = new MessageProcessor(messageService);

			var rabbitMqService = new RabbitMQConsumerService();

			// Consume email messages
			rabbitMqService.ConsumeMessages("emailQueue", (model, ea) =>
			{
				var body = ea.Body.ToArray();
				var message = Encoding.UTF8.GetString(body);
				emailProcessor.Process(message);
			});

			// Consume chat messages
			rabbitMqService.ConsumeMessages("messageQueue", (model, ea) =>
			{
				var body = ea.Body.ToArray();
				var message = Encoding.UTF8.GetString(body);
				messageProcessor.Process(message);
			});

			Console.WriteLine(" [*] Waiting for messages.");
			Console.ReadLine();

			// Clean up
			rabbitMqService.Dispose();
		}
	}
}
