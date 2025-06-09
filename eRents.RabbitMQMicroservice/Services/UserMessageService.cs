using eRents.Shared.Messaging;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Configuration;
using System.Text.Json;

namespace eRents.RabbitMQMicroservice.Services
{
	public class UserMessageService : IMessageService
	{
		private readonly ILogger<UserMessageService> _logger;
		private readonly ISignalRNotificationService _signalRService;
		private readonly HttpClient _httpClient;
		private readonly string _webApiBaseUrl;

		public UserMessageService(
			ILogger<UserMessageService> logger,
			ISignalRNotificationService signalRService,
			HttpClient httpClient,
			IConfiguration configuration)
		{
			_logger = logger;
			_signalRService = signalRService;
			_httpClient = httpClient;
			_webApiBaseUrl = configuration["WebApi:BaseUrl"] ?? "http://localhost:5000";
		}

		public async void HandleUserMessage(UserMessage message)
		{
			try
			{
				_logger.LogInformation("Processing message from {SenderUsername} to {RecipientUsername}", 
					message.SenderUsername, message.RecipientUsername);

				// Parse user IDs from usernames
				var senderId = ParseUserIdFromUsername(message.SenderUsername);
				var receiverId = ParseUserIdFromUsername(message.RecipientUsername);

				if (senderId == 0 || receiverId == 0)
				{
					_logger.LogError("Failed to parse user IDs from usernames: {SenderUsername} -> {SenderId}, {RecipientUsername} -> {ReceiverId}",
						message.SenderUsername, senderId, message.RecipientUsername, receiverId);
					return;
				}

				// Persist message to database via WebAPI
				await PersistMessageToDatabase(senderId, receiverId, message.Body);

				// Send SignalR notification for real-time delivery
				await _signalRService.SendMessageNotificationAsync(senderId, receiverId, message.Body);

				_logger.LogInformation("Successfully processed message from {SenderUsername} to {RecipientUsername}",
					message.SenderUsername, message.RecipientUsername);
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error processing message from {SenderUsername} to {RecipientUsername}",
					message.SenderUsername, message.RecipientUsername);
			}
		}

		private int ParseUserIdFromUsername(string username)
		{
			// Handle format "user_{id}"
			if (username.StartsWith("user_") && int.TryParse(username.Substring(5), out var userId))
			{
				return userId;
			}

			// For actual usernames, we'd need to call the WebAPI to resolve them
			// For now, we'll return 0 which indicates failure
			_logger.LogWarning("Unable to parse user ID from username: {Username}", username);
			return 0;
		}

		private async Task PersistMessageToDatabase(int senderId, int receiverId, string messageText)
		{
			try
			{
				var messageData = new
				{
					senderId,
					receiverId,
					messageText,
					dateSent = DateTime.UtcNow
				};

				var json = JsonSerializer.Serialize(messageData);
				var content = new StringContent(json, System.Text.Encoding.UTF8, "application/json");

				var response = await _httpClient.PostAsync($"{_webApiBaseUrl}/api/internal/messages/persist", content);
				
				if (!response.IsSuccessStatusCode)
				{
					var errorContent = await response.Content.ReadAsStringAsync();
					_logger.LogWarning("Failed to persist message to database. Status: {StatusCode}, Error: {Error}",
						response.StatusCode, errorContent);
				}
				else
				{
					_logger.LogInformation("Message persisted to database successfully");
				}
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error persisting message to database");
			}
		}
	}
}
