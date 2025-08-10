using eRents.RabbitMQMicroservice.Processors;
using eRents.RabbitMQMicroservice.Services;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using System.Text;
using RabbitMQ.Client.Events;
using Newtonsoft.Json;
using eRents.Shared.DTOs;

namespace eRents.RabbitMQMicroservice
{
	class Program
	{
		static async Task Main(string[] args)
		{
			// Build configuration
			var configuration = new ConfigurationBuilder()
				.SetBasePath(Directory.GetCurrentDirectory())
				.AddJsonFile("appsettings.json", optional: true, reloadOnChange: true)
				.AddEnvironmentVariables()
				.Build();

			// Create host
			var host = Host.CreateDefaultBuilder(args)
				.ConfigureServices((hostContext, services) =>
				{
					// Configure services
					services.AddSingleton<IConfiguration>(configuration);
					services.AddLogging(builder =>
					{
						builder.AddConsole();
						builder.SetMinimumLevel(LogLevel.Information);
					});

					// Register email service
					services.AddTransient<IEmailService, SmtpEmailService>();

					// Register message service with HttpClient
					services.AddHttpClient<IMessageService, UserMessageService>();

					// Register SignalR notification service
					services.AddHttpClient<ISignalRNotificationService, SignalRNotificationService>();

					// Register processors
					services.AddTransient<ChatMessageProcessor>();
					services.AddTransient<EmailProcessor>();
					services.AddTransient<BookingNotificationProcessor>();
					services.AddTransient<ReviewNotificationProcessor>();

					// Register RabbitMQ consumer service
					services.AddSingleton<RabbitMQConsumerService>(provider =>
					{
						var config = provider.GetRequiredService<IConfiguration>();
						var hostname = config["RabbitMQ:HostName"] ?? "localhost";
						var port = int.Parse(config["RabbitMQ:Port"] ?? "5672");
						var username = config["RabbitMQ:UserName"] ?? "guest";
						var password = config["RabbitMQ:Password"] ?? "guest";

						return new RabbitMQConsumerService(hostname, port, username, password);
					});
				})
				.Build();

			// Get services
			var serviceProvider = host.Services;
			var logger = serviceProvider.GetRequiredService<ILogger<Program>>();
			var rabbitMqService = serviceProvider.GetRequiredService<RabbitMQConsumerService>();
            var config = serviceProvider.GetRequiredService<IConfiguration>();

			// Get processors
			var chatMessageProcessor = serviceProvider.GetRequiredService<ChatMessageProcessor>();
			var emailProcessor = serviceProvider.GetRequiredService<EmailProcessor>();
			var bookingProcessor = serviceProvider.GetRequiredService<BookingNotificationProcessor>();
			var reviewProcessor = serviceProvider.GetRequiredService<ReviewNotificationProcessor>();

			try
			{
				logger.LogInformation("Starting RabbitMQ Microservice...");

				// Set up consumers for each queue
				// 1. Chat messages
				rabbitMqService.ConsumeMessages("messageQueue", (model, ea) =>
				{
					try
					{
						chatMessageProcessor.Process(model, ea);
					}
					catch (Exception ex)
					{
						logger.LogError(ex, "Error processing chat message");
					}
				});
				logger.LogInformation("Started consuming from messageQueue");

				// 2. Email notifications
				// Ensure exchange/queue binding matches the WebApi publisher
				var emailExchange = config["RabbitMQ:EmailExchange"] ?? "emails.exchange";
				var emailRoutingKey = config["RabbitMQ:EmailRoutingKey"] ?? "emails.send";
				var emailExchangeType = config["RabbitMQ:EmailExchangeType"] ?? "topic";
				var emailQueue = config["RabbitMQ:EmailQueue"] ?? "emailQueue";

				rabbitMqService.EnsureBinding(emailExchange, emailExchangeType, emailQueue, emailRoutingKey);

				rabbitMqService.ConsumeMessages(emailQueue, async (model, ea) =>
				{
					try
					{
						var body = ea.Body.ToArray();
						var message = Encoding.UTF8.GetString(body);
						await emailProcessor.Process(message);
					}
					catch (Exception ex)
					{
						logger.LogError(ex, "Error processing email notification");
					}
				});
				logger.LogInformation("Started consuming from emailQueue");

				// 3. Booking notifications
				rabbitMqService.ConsumeMessages("bookingQueue", async (model, ea) =>
				{
					try
					{
						var body = ea.Body.ToArray();
						var message = Encoding.UTF8.GetString(body);
						await bookingProcessor.Process(message);
					}
					catch (Exception ex)
					{
						logger.LogError(ex, "Error processing booking notification");
					}
				});
				logger.LogInformation("Started consuming from bookingQueue");

				// 4. Review notifications
				rabbitMqService.ConsumeMessages("reviewQueue", async (model, ea) =>
				{
					try
					{
						await reviewProcessor.Process(model, ea);
					}
					catch (Exception ex)
					{
						logger.LogError(ex, "Error processing review notification");
					}
				});
				logger.LogInformation("Started consuming from reviewQueue");

				logger.LogInformation("RabbitMQ Microservice is running. Press Ctrl+C to exit.");
				
				// Keep the service running
				await host.RunAsync();
			}
			catch (Exception ex)
			{
				logger.LogError(ex, "Fatal error in RabbitMQ Microservice");
				throw;
			}
			finally
			{
				// Clean up
				rabbitMqService?.Dispose();
			}
		}
	}
}
