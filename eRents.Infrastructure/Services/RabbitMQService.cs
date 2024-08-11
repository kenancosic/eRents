using Newtonsoft.Json;
using RabbitMQ.Client;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eRents.Infrastructure.Services
{
	public class RabbitMQService : IRabbitMQService
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

			_connection = factory.CreateConnection();
			_channel = _connection.CreateModel();
		}

		public async Task PublishMessageAsync(string queueName, object message)
		{
			var json = JsonConvert.SerializeObject(message);
			var body = Encoding.UTF8.GetBytes(json);

			_channel.QueueDeclare(queue: queueName, durable: false, exclusive: false, autoDelete: false, arguments: null);
			_channel.BasicPublish(exchange: "", routingKey: queueName, basicProperties: null, body: body);

			Console.WriteLine($"Message published to queue {queueName}: {json}");
		}

		public void Dispose()
		{
			_channel?.Dispose();
			_connection?.Dispose();
		}
	}
}
