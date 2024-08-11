using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using System;
using System.Text;

namespace eRents.RabbitMQMicroservice.Services
{
	public class RabbitMQConsumerService : IDisposable
	{
		private readonly IConnection _connection;
		private readonly IModel _channel;

		public RabbitMQConsumerService(string hostname = "localhost", int port = 5672, string username = "guest", string password = "guest")
		{
			var factory = new ConnectionFactory()
			{
				HostName = hostname,
				Port = port,
				UserName = username,
				Password = password
			};

			try
			{
				_connection = factory.CreateConnection();
				_channel = _connection.CreateModel();
				Console.WriteLine("Connected to RabbitMQ server successfully.");
			}
			catch (Exception ex)
			{
				Console.WriteLine($"Failed to connect to RabbitMQ server: {ex.Message}");
				throw;
			}
		}

		public void ConsumeMessages(string queueName, EventHandler<BasicDeliverEventArgs> onMessageReceived, bool autoAck = true)
		{
			try
			{
				var consumer = new EventingBasicConsumer(_channel);
				consumer.Received += onMessageReceived;
				_channel.BasicConsume(queue: queueName, autoAck: autoAck, consumer: consumer);
				Console.WriteLine($"Started consuming messages from {queueName}");
			}
			catch (Exception ex)
			{
				Console.WriteLine($"Failed to consume messages from queue: {queueName}. Error: {ex.Message}");
				throw;
			}
		}

		public void Dispose()
		{
			_channel?.Dispose();
			_connection?.Dispose();
			Console.WriteLine("RabbitMQ connection and channel disposed.");
		}
	}
}
