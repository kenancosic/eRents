using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using System;
using eRents.Shared.Services;

namespace eRents.RabbitMQMicroservice.Services
{
	public class RabbitMQConsumerService : IDisposable
	{
		private readonly IConnection _connection;
		private readonly IChannel _channel;

		public RabbitMQConsumerService(string hostname = "localhost", int port = 5672, string username = "guest", string password = "guest")
		{
			var factory = new ConnectionFactory()
			{
				HostName = hostname,
				Port = port,
				UserName = username,
				Password = password,
			};

			_connection = factory.CreateConnectionAsync().GetAwaiter().GetResult();
			_channel = _connection.CreateChannelAsync().GetAwaiter().GetResult();
		}

		public void EnsureBinding(string exchangeName, string exchangeType, string queueName, string routingKey)
		{
			// Declare exchange and queue as durable and bind them. Safe to call repeatedly.
			_channel.ExchangeDeclareAsync(exchange: exchangeName, type: exchangeType, durable: true, autoDelete: false, arguments: null).GetAwaiter().GetResult();
			_channel.QueueDeclareAsync(queue: queueName, durable: true, exclusive: false, autoDelete: false, arguments: null).GetAwaiter().GetResult();
			_channel.QueueBindAsync(queue: queueName, exchange: exchangeName, routingKey: routingKey).GetAwaiter().GetResult();
		}

		public void ConsumeMessages(string queueName, EventHandler<BasicDeliverEventArgs> onMessageReceived, bool autoAck = true)
		{
			_channel.QueueDeclareAsync(queue: queueName, durable: true, exclusive: false, autoDelete: false, arguments: null).GetAwaiter().GetResult();

			var consumer = new AsyncEventingBasicConsumer(_channel);
			consumer.ReceivedAsync += async (sender, ea) =>
			{
				// Bridge to existing handler signature
				onMessageReceived(sender!, ea);
				await Task.CompletedTask;
			};

			_channel.BasicConsumeAsync(queue: queueName, autoAck: autoAck, consumer: consumer).GetAwaiter().GetResult();
			Console.WriteLine($"Started consuming messages from {queueName}");
		}

		public void Dispose()
		{
			_channel?.CloseAsync().GetAwaiter().GetResult();
			_channel?.Dispose();
			_connection?.CloseAsync().GetAwaiter().GetResult();
			_connection?.Dispose();
			GC.SuppressFinalize(this);
		}
	}
}
