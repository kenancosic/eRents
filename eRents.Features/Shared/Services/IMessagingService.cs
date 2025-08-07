using eRents.Features.Core.Models.Shared;

namespace eRents.Features.Shared.Services
{
    /// <summary>
    /// Consolidated messaging service for chat and real-time communication
    /// Combines MessageHandler, RealTime, and UserLookup functionality
    /// </summary>
    public interface IMessagingService
    {
        #region Core Messaging Operations

        Task<MessageResponse> SendMessageAsync(int senderId, SendMessageRequest request);
        Task<IEnumerable<MessageResponse>> GetConversationAsync(int userId, int contactId);
        Task<IEnumerable<object>> GetContactsAsync(int userId);
        Task MarkMessageAsReadAsync(int messageId);
        Task<bool> SendPropertyOfferMessageAsync(int senderId, int receiverId, int propertyId, string offerMessage);
        Task<MessageResponse> SendPropertyOfferMessageAsync(int senderId, int receiverId, int propertyId);

        #endregion

        #region Real-Time Operations

        Task SendRealTimeMessageAsync(int senderId, int receiverId, string messageText, DateTime createdAt);
        Task SendSystemNotificationAsync(int userId, string notification);
        Task BroadcastUserStatusAsync(int userId, bool isOnline);
        Task SendMessageToUserAsync(int receiverId, string eventName, object data);

        #endregion
    }
}