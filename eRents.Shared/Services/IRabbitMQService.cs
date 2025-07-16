using eRents.Shared.DTOs;

namespace eRents.Shared.Services;

/// <summary>
/// RabbitMQ service interface for message publishing and handling
/// </summary>
public interface IRabbitMQService
{
    /// <summary>
    /// Publish a user message to the message queue
    /// </summary>
    Task PublishUserMessageAsync(UserMessage message);

    /// <summary>
    /// Publish a booking notification message to the queue
    /// </summary>
    Task PublishBookingNotificationAsync(BookingNotificationMessage message);

    /// <summary>
    /// Generic message publishing method
    /// </summary>
    Task PublishMessageAsync<T>(T message, string queueName) where T : class;

    /// <summary>
    /// Check if the RabbitMQ service is connected
    /// </summary>
    bool IsConnected { get; }

    /// <summary>
    /// Get health status of the RabbitMQ connection
    /// </summary>
    Task<bool> HealthCheckAsync();
} 