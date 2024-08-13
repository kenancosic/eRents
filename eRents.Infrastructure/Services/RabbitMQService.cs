using Newtonsoft.Json;
using RabbitMQ.Client;
using System.Text;

namespace eRents.Infrastructure.Services
{
	public class RabbitMQService : RabbitMQBaseService, IRabbitMQService
	{
		public RabbitMQService(string hostname = "localhost", int port = 5672, string username = "guest", string password = "guest")
				: base(hostname, port, username, password)
		{
		}

		public async Task PublishMessageAsync(string queueName, object message)
		{
			var json = JsonConvert.SerializeObject(message);
			var body = Encoding.UTF8.GetBytes(json);

			_channel.QueueDeclare(queue: queueName, durable: false, exclusive: false, autoDelete: false, arguments: null);
			_channel.BasicPublish(exchange: "", routingKey: queueName, basicProperties: null, body: body);

			Console.WriteLine($"Message published to queue {queueName}: {json}");
		}
	}
}
