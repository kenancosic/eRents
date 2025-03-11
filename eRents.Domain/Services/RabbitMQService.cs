using Newtonsoft.Json;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using System;
using System.Text;
using System.Threading.Tasks;

namespace eRents.Domain.Services;

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

		_channel.QueueDeclare(queue: queueName, durable: true, exclusive: false, autoDelete: false, arguments: null);
		var properties = _channel.CreateBasicProperties();
		properties.Persistent = true;

		_channel.BasicPublish(exchange: "", routingKey: queueName, basicProperties: properties, body: body);
		await Task.CompletedTask;

		Console.WriteLine($"Message published to queue {queueName}: {json}");
	}

	public async Task SubscribeAsync(string queueName, Func<string, Task> onMessageReceived)
	{
		var consumer = new EventingBasicConsumer(_channel);
		consumer.Received += async (model, ea) =>
		{
			var body = ea.Body.ToArray();
			var message = Encoding.UTF8.GetString(body);
			await onMessageReceived(message);
		};

		_channel.BasicConsume(queue: queueName, autoAck: true, consumer: consumer);
		await Task.CompletedTask;

		Console.WriteLine($"Subscribed to queue {queueName}");
	}
}