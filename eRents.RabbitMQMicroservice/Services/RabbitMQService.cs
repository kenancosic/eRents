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
        private readonly IChannel _channel;

        public RabbitMQService(string hostname = "localhost", int port = 5672, string username = "guest", string password = "guest")
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

        public void DeclareQueue(string queueName, bool durable = true, bool exclusive = false, bool autoDelete = false, IDictionary<string, object?>? arguments = null)
        {
            _channel.QueueDeclareAsync(queue: queueName,
                                       durable: durable,
                                       exclusive: exclusive,
                                       autoDelete: autoDelete,
                                       arguments: arguments).GetAwaiter().GetResult();
            Console.WriteLine($"Queue '{queueName}' declared.");
        }

        public async Task PublishMessageAsync(string queueName, object message)
        {
            var jsonMessage = JsonSerializer.Serialize(message);
            var body = Encoding.UTF8.GetBytes(jsonMessage);

            var properties = new BasicProperties();
            properties.Persistent = true;

            await _channel.BasicPublishAsync(exchange: "",
                                             routingKey: queueName,
                                             mandatory: false,
                                             basicProperties: properties,
                                             body: body);
            Console.WriteLine($" [x] Sent {jsonMessage} to queue '{queueName}'");
        }

        public Task PublishUserMessageAsync(UserMessage message)
        {
            return PublishMessageAsync("messageQueue", message);
        }

        public Task PublishBookingNotificationAsync(BookingNotificationMessage message)
        {
            return PublishMessageAsync("bookingQueue", message);
        }

        public Task PublishRefundNotificationAsync(RefundNotificationMessage message)
        {
            return PublishMessageAsync("refundQueue", message);
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

        public async Task SubscribeAsync(string queueName, Func<string, Task> onMessageReceived)
        {
            var consumer = new AsyncEventingBasicConsumer(_channel);
            consumer.ReceivedAsync += async (model, ea) =>
            {
                var bodyBytes = ea.Body.ToArray();
                var message = Encoding.UTF8.GetString(bodyBytes);
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

            await _channel.BasicConsumeAsync(queue: queueName,
                                             autoAck: true, // Set to false for manual acknowledgment and error handling (e.g., Nack)
                                             consumer: consumer);

            Console.WriteLine($" [*] Subscribed to queue '{queueName}'. Waiting for messages.");
        }

        public async Task DisposeAsync()
        {
            await _channel.CloseAsync();
            _channel.Dispose();
            await _connection.CloseAsync();
            _connection.Dispose();
            GC.SuppressFinalize(this);
        }
    }
}