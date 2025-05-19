using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using System;
using eRents.Shared.Services;

namespace eRents.RabbitMQMicroservice.Services
{
	public class RabbitMQConsumerService : IDisposable
	{
		private readonly IConnection _connection;
		private readonly RabbitMQ.Client.IModel _channel;

		public RabbitMQConsumerService(string hostname = "localhost", int port = 5672, string username = "guest", string password = "guest")
		{
			var factory = new ConnectionFactory()
			{
				HostName = hostname,
				Port = port,
				UserName = username,
				Password = password,
			};

			_connection = factory.CreateConnection();
			_channel = _connection.CreateModel();
		}

		public void ConsumeMessages(string queueName, EventHandler<BasicDeliverEventArgs> onMessageReceived, bool autoAck = true)
		{
			_channel.QueueDeclare(queue: queueName, durable: true, exclusive: false, autoDelete: false, arguments: null);
			
			var consumer = new EventingBasicConsumer(_channel);
			consumer.Received += onMessageReceived;
			
			_channel.BasicConsume(queue: queueName, autoAck: autoAck, consumer: consumer);
			Console.WriteLine($"Started consuming messages from {queueName}");
		}

		public void Dispose()
		{
			_channel?.Close();
			_channel?.Dispose();
			_connection?.Close();
			_connection?.Dispose();
			GC.SuppressFinalize(this);
		}
	}
}
