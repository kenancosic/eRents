using eRents.Domain.Entities;
using eRents.Infrastructure.Data.Shared;

namespace eRents.Infrastructure.Data.Repositories
{
	public interface IMessageRepository : IBaseRepository<Message>
	{
		Task<IEnumerable<Message>> GetMessagesBetweenUsersAsync(int senderId, int receiverId);
		Task MarkMessageAsReadAsync(int messageId);
		Task<IEnumerable<Message>> GetMessagesAsync(int senderId, int receiverId);
	}
}
