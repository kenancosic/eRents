using System.Threading.Tasks;

namespace eRents.RabbitMQMicroservice.Services
{
    public interface ISignalRNotificationService
    {
        Task SendMessageNotificationAsync(int senderId, int receiverId, string message);
        Task SendBookingNotificationAsync(int userId, int bookingId, string notification);
        Task SendReviewNotificationAsync(int propertyOwnerId, int reviewId, string notification);
        Task SendSystemNotificationAsync(int userId, string notification);
    }
}