using eRents.Domain.Services;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;

namespace eRents.RabbitMQMicroservice.Services
{
	public class RabbitMQConsumerService : RabbitMQBaseService
	{
		public RabbitMQConsumerService(string hostname = "localhost", int port = 5672, string username = "guest", string password = "guest")
				: base(hostname, port, username, password)
		{
		}

		public void ConsumeMessages(string queueName, EventHandler<BasicDeliverEventArgs> onMessageReceived, bool autoAck = true)
		{
			//var consumer = new EventingBasicConsumer(_channel);
			//consumer.Received += onMessageReceived;
			//_channel.BasicConsume(queue: queueName, autoAck: autoAck, consumer: consumer);
			//Console.WriteLine($"Started consuming messages from {queueName}");
		}
	}
}
