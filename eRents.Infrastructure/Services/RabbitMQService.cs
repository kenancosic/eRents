using RabbitMQ.Client;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eRents.Infrastructure.Services
{
	public class RabbitMQService : IDisposable
	{
		private readonly IConnection _connection;
		private readonly IModel _channel;

		public RabbitMQService(string hostname = "localhost", int port = 5672, string username = "guest", string password = "guest")
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

		public void PublishMessage(string queueName, string message)
		{
			try
			{
				var body = Encoding.UTF8.GetBytes(message);
				_channel.BasicPublish(exchange: "", routingKey: queueName, basicProperties: null, body: body);
				Console.WriteLine($" [x] Sent message to {queueName}: {message}");
			}
			catch (Exception ex)
			{
				Console.WriteLine($"Failed to publish message to queue: {queueName}. Error: {ex.Message}");
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
