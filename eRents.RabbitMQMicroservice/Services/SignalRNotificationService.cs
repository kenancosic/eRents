using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using System.Net.Http;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;

namespace eRents.RabbitMQMicroservice.Services
{
    public class SignalRNotificationService : ISignalRNotificationService
    {
        private readonly HttpClient _httpClient;
        private readonly IConfiguration _configuration;
        private readonly ILogger<SignalRNotificationService> _logger;
        private readonly string _webApiBaseUrl;

        public SignalRNotificationService(
            HttpClient httpClient,
            IConfiguration configuration,
            ILogger<SignalRNotificationService> logger)
        {
            _httpClient = httpClient;
            _configuration = configuration;
            _logger = logger;
            _webApiBaseUrl = _configuration["WebApi:BaseUrl"] ?? "http://localhost:5000";
        }

        public async Task SendMessageNotificationAsync(int senderId, int receiverId, string message)
        {
            try
            {
                var notification = new
                {
                    senderId,
                    receiverId,
                    message,
                    timestamp = DateTime.UtcNow
                };

                await SendNotificationAsync($"{_webApiBaseUrl}/api/realtime/notifications/message", notification);
                _logger.LogInformation("Message notification sent from {SenderId} to {ReceiverId}", senderId, receiverId);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to send message notification from {SenderId} to {ReceiverId}", senderId, receiverId);
            }
        }

        public async Task SendBookingNotificationAsync(int userId, int bookingId, string notification)
        {
            try
            {
                var notificationData = new
                {
                    userId,
                    bookingId,
                    notification,
                    timestamp = DateTime.UtcNow
                };

                await SendNotificationAsync($"{_webApiBaseUrl}/api/realtime/notifications/booking", notificationData);
                _logger.LogInformation("Booking notification sent to user {UserId} for booking {BookingId}", userId, bookingId);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to send booking notification to user {UserId} for booking {BookingId}", userId, bookingId);
            }
        }

        public async Task SendReviewNotificationAsync(int propertyOwnerId, int reviewId, string notification)
        {
            try
            {
                var notificationData = new
                {
                    propertyOwnerId,
                    reviewId,
                    notification,
                    timestamp = DateTime.UtcNow
                };

                await SendNotificationAsync($"{_webApiBaseUrl}/api/realtime/notifications/review", notificationData);
                _logger.LogInformation("Review notification sent to property owner {PropertyOwnerId} for review {ReviewId}", propertyOwnerId, reviewId);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to send review notification to property owner {PropertyOwnerId} for review {ReviewId}", propertyOwnerId, reviewId);
            }
        }

        public async Task SendSystemNotificationAsync(int userId, string notification)
        {
            try
            {
                var notificationData = new
                {
                    userId,
                    notification,
                    timestamp = DateTime.UtcNow
                };

                await SendNotificationAsync($"{_webApiBaseUrl}/api/realtime/notifications/system", notificationData);
                _logger.LogInformation("System notification sent to user {UserId}", userId);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to send system notification to user {UserId}", userId);
            }
        }

        private async Task SendNotificationAsync(string endpoint, object data)
        {
            var json = JsonSerializer.Serialize(data);
            var content = new StringContent(json, Encoding.UTF8, "application/json");

            var response = await _httpClient.PostAsync(endpoint, content);
            if (!response.IsSuccessStatusCode)
            {
                var errorContent = await response.Content.ReadAsStringAsync();
                _logger.LogWarning("Failed to send notification to {Endpoint}. Status: {StatusCode}, Error: {Error}", 
                    endpoint, response.StatusCode, errorContent);
            }
        }
    }
}