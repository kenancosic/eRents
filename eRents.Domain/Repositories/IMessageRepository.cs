using eRents.Domain.Models;
using eRents.Domain.Shared;

namespace eRents.Domain.Repositories
{
	public interface IMessageRepository : IBaseRepository<Message>
	{
		Task<IEnumerable<Message>> GetMessagesBetweenUsersAsync(int senderId, int receiverId);
		Task MarkMessageAsReadAsync(int messageId);
		Task<IEnumerable<Message>> GetMessagesAsync(int senderId, int receiverId);
	}
}
