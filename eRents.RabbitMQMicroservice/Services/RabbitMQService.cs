using Microsoft.EntityFrameworkCore.Metadata;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using System;
using System.Collections.Generic;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;
using eRents.Shared.Services;
using eRents.Shared.DTOs;

namespace eRents.RabbitMQMicroservice.Services
{
	public class RabbitMQService : IRabbitMQService
	{
		private readonly IConnection _connection;
		private readonly RabbitMQ.Client.IModel _channel;

		public RabbitMQService(string hostname = "localhost", int port = 5672, string username = "guest", string password = "guest")
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

		public void DeclareQueue(string queueName, bool durable = true, bool exclusive = false, bool autoDelete = false, IDictionary<string, object>? arguments = null)
		{
			_channel.QueueDeclare(queue: queueName,
													 durable: durable,
													 exclusive: exclusive,
													 autoDelete: autoDelete,
													 arguments: arguments);
			Console.WriteLine($"Queue '{queueName}' declared.");
		}

		public Task PublishMessageAsync(string queueName, object message)
		{
			var jsonMessage = JsonSerializer.Serialize(message);
			var body = Encoding.UTF8.GetBytes(jsonMessage);

			var properties = _channel.CreateBasicProperties();
			properties.Persistent = true;

			_channel.BasicPublish(exchange: "",
													 routingKey: queueName,
													 basicProperties: properties,
													 body: body);
			Console.WriteLine($" [x] Sent {jsonMessage} to queue '{queueName}'");
			return Task.CompletedTask;
		}

		public Task PublishUserMessageAsync(UserMessage message)
		{
			return PublishMessageAsync("messageQueue", message);
		}

		public Task PublishBookingNotificationAsync(BookingNotificationMessage message)
		{
			return PublishMessageAsync("bookingQueue", message);
		}

		public Task PublishMessageAsync<T>(T message, string queueName) where T : class
		{
			return PublishMessageAsync(queueName, message);
		}

		public bool IsConnected => _connection?.IsOpen ?? false;

		public Task<bool> HealthCheckAsync()
		{
			return Task.FromResult(IsConnected);
		}

		public Task SubscribeAsync(string queueName, Func<string, Task> onMessageReceived)
		{
			var consumer = new EventingBasicConsumer(_channel);
			consumer.Received += async (model, ea) =>
			{
				var body = ea.Body.ToArray();
				var message = Encoding.UTF8.GetString(body);
				Console.WriteLine($" [x] Received '{message}' from queue '{queueName}'");
				try
				{
					await onMessageReceived(message);
				}
				catch (Exception ex)
				{
					Console.WriteLine($"Error processing message: {ex.Message}");
				}
			};

			_channel.BasicConsume(queue: queueName,
													 autoAck: true, // Set to false for manual acknowledgment and error handling (e.g., Nack)
													 consumer: consumer);

			Console.WriteLine($" [*] Subscribed to queue '{queueName}'. Waiting for messages.");
			return Task.CompletedTask;
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