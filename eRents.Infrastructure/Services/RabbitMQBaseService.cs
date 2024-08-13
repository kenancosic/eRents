using RabbitMQ.Client;

namespace eRents.Infrastructure.Services
{
	public abstract class RabbitMQBaseService : IDisposable
	{
		protected readonly IConnection _connection;
		protected readonly IModel _channel;

		protected RabbitMQBaseService(string hostname = "localhost", int port = 5672, string username = "guest", string password = "guest")
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

		public void Dispose()
		{
			_channel?.Dispose();
			_connection?.Dispose();
		}
	}
}
