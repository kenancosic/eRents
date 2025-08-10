using System;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using RabbitMQ.Client;
using eRents.Shared.DTOs;
using eRents.Shared.Services;

namespace eRents.WebApi.Services
{
	// Minimal publisher implementation for academic decoupling demo
	// Publishes EmailMessage to RabbitMQ; a separate worker consumes and sends via SMTP
    public class RabbitMqEmailPublisher : IEmailService
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<RabbitMqEmailPublisher> _logger;

        public RabbitMqEmailPublisher(IConfiguration configuration, ILogger<RabbitMqEmailPublisher> logger)
        {
            _configuration = configuration;
            _logger = logger;
        }

		public async Task SendEmailNotificationAsync(EmailMessage message, CancellationToken ct = default)
        {
            var host = _configuration["RabbitMq:HostName"] ?? "localhost";
            var user = _configuration["RabbitMq:UserName"] ?? "guest";
            var pass = _configuration["RabbitMq:Password"] ?? "guest";
            var portStr = _configuration["RabbitMq:Port"];
            int port = 0;
            if (!int.TryParse(portStr, out port)) port = 5672;

            var exchange = _configuration["RabbitMq:EmailExchange"] ?? "emails.exchange";
            var routingKey = _configuration["RabbitMq:EmailRoutingKey"] ?? "emails.send";
            var exchangeType = _configuration["RabbitMq:EmailExchangeType"] ?? ExchangeType.Topic;

            try
            {
                var factory = new ConnectionFactory()
                {
                    HostName = host,
                    UserName = user,
                    Password = pass,
                    Port = port,
                    AutomaticRecoveryEnabled = true,
                    ClientProvidedName = "myAppEmailPublisher"
                };

				await using var connection = await factory.CreateConnectionAsync(ct);
				await using var channel = await connection.CreateChannelAsync(options: null, cancellationToken: ct);

				await channel.ExchangeDeclareAsync(
					exchange: exchange,
					type: exchangeType,
					durable: true,
					autoDelete: false,
					arguments: null,
					cancellationToken: ct);

				var payload = System.Text.Json.JsonSerializer.Serialize(message);
				var body = Encoding.UTF8.GetBytes(payload);

				var props = new BasicProperties();
				props.ContentType = "application/json";
				props.DeliveryMode = DeliveryModes.Persistent; // persistent
				props.MessageId = Guid.NewGuid().ToString("N");
				// Use MessageId as CorrelationId for tracing since EmailMessage lacks this field
				props.CorrelationId = props.MessageId;
				props.Type = nameof(EmailMessage);

				await channel.BasicPublishAsync(
					exchange: exchange,
					routingKey: routingKey,
					mandatory: false,
					basicProperties: props,
					body: body,
					cancellationToken: ct);
				_logger.LogInformation("Published email message to RabbitMQ. CorrelationId={CorrelationId} To={To}", props.CorrelationId, message.To ?? message.Email);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to publish email message to RabbitMQ");
                // For minimal demo, swallow exception to avoid breaking the request flow
                // In production, consider retry, circuit breaker, or fallback
            }
        }
    }
}
