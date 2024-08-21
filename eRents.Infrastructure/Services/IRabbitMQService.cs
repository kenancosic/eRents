namespace eRents.Infrastructure.Services
{
	public interface IRabbitMQService
	{
		Task PublishMessageAsync(string queueName, object message);
		Task SubscribeAsync(string queueName, Func<string, Task> onMessageReceived);
	}
}
