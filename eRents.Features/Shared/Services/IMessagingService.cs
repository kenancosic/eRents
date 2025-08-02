using eRents.Features.Shared.DTOs;
using eRents.Shared.DTOs;
using eRents.Features.UserManagement.DTOs;

namespace eRents.Features.Shared.Services
{
    /// <summary>
    /// Consolidated messaging service for chat and real-time communication
    /// Combines MessageHandler, RealTime, and UserLookup functionality
    /// </summary>
    public interface IMessagingService
    {
        #region Core Messaging Operations

        /// <summary>
        /// Send a message between users with RabbitMQ and SignalR integration
        /// </summary>
        Task<MessageResponse> SendMessageAsync(int senderId, SendMessageRequest request);

        /// <summary>
        /// Get conversation between two users
        /// </summary>
        Task<IEnumerable<MessageResponse>> GetConversationAsync(int userId, int contactId);

        /// <summary>
        /// Get all contacts/users for a specific user
        /// </summary>
        Task<IEnumerable<UserResponse>> GetContactsAsync(int userId);

        /// <summary>
        /// Mark a message as read
        /// </summary>
        Task MarkMessageAsReadAsync(int messageId);

        /// <summary>
        /// Send a property offer message with custom content
        /// </summary>
        Task<bool> SendPropertyOfferMessageAsync(int senderId, int receiverId, int propertyId, string offerMessage);

        /// <summary>
        /// Send a property offer message (generates default message)
        /// </summary>
        Task<MessageResponse> SendPropertyOfferMessageAsync(int senderId, int receiverId, int propertyId);

        #endregion

        #region Real-Time Operations

        /// <summary>
        /// Send real-time message via SignalR
        /// </summary>
        Task SendRealTimeMessageAsync(int senderId, int receiverId, string messageText, DateTime createdAt);

        /// <summary>
        /// Send system notification to specific user
        /// </summary>
        Task SendSystemNotificationAsync(int userId, string notification);

        /// <summary>
        /// Broadcast user status change (online/offline)
        /// </summary>
        Task BroadcastUserStatusAsync(int userId, bool isOnline);

        /// <summary>
        /// Send custom event to user
        /// </summary>
        Task SendMessageToUserAsync(int receiverId, string eventName, object data);

        #endregion
    }
}