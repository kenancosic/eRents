using eRents.Domain.Entities;
using eRents.Infrastructure.Data.Context;
using eRents.Infrastructure.Data.Shared;
using Microsoft.EntityFrameworkCore;

namespace eRents.Infrastructure.Data.Repositories
{
	public class MessageRepository : BaseRepository<Message>, IMessageRepository
	{
		public MessageRepository(ERentsContext context) : base(context) { }

		public async Task<IEnumerable<Message>> GetMessagesBetweenUsersAsync(int senderId, int receiverId)
		{
			return await _context.Messages
					.Where(m => (m.SenderId == senderId && m.ReceiverId == receiverId) ||
											(m.SenderId == receiverId && m.ReceiverId == senderId))
					.OrderBy(m => m.DateSent)
					.ToListAsync();
		}

		public async Task MarkMessageAsReadAsync(int messageId)
		{
			var message = await _context.Messages.FindAsync(messageId);
			if (message != null)
			{
				message.IsRead = true;
				await _context.SaveChangesAsync();
			}
		}
		public async Task<IEnumerable<Message>> GetMessagesAsync(int senderId, int receiverId)
		{
			return await _context.Messages
					.Where(m => m.SenderId == senderId && m.ReceiverId == receiverId)
					.ToListAsync();
		}

	}
}
