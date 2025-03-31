using Microsoft.EntityFrameworkCore.Metadata;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using System;
using System.Threading.Tasks;

namespace eRents.Domain.Services
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
				Password = password,
				//DispatchConsumersAsync = true
			};

			//_connection = factory.CreateConnection();
			//_channel = _connection.CreateModel(); // Fixed the pointer syntax error here
		}

		public void Dispose()
		{
			//_channel?.Dispose();
			_connection?.Dispose();
		}
	}
}