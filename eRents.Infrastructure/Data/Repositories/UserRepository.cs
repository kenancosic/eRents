using eRents.Domain.Entities;
using eRents.Infrastructure.Data.Context;
using eRents.Infrastructure.Data.Shared;
using eRents.Shared.Exceptions;
using Microsoft.EntityFrameworkCore;

namespace eRents.Infrastructure.Data.Repositories
{
	public class UserRepository : BaseRepository<User>, IUserRepository
	{
		public UserRepository(ERentsContext context) : base(context) { }

		public async Task<User> GetByUsernameAsync(string username)
		{
			return await _context.Users.FirstOrDefaultAsync(u => u.Username == username);
		}

		public async Task<User> GetByEmailAsync(string email)
		{
			return await _context.Users.FirstOrDefaultAsync(u => u.Email == email);
		}

		public async Task<User> GetUserByUsernameOrEmailAsync(string usernameOrEmail)
		{
			try
			{
				return await _context.Users.FirstOrDefaultAsync(u => u.Username == usernameOrEmail || u.Email == usernameOrEmail)
							 ?? throw new KeyNotFoundException("User not found.");
			}
			catch (Exception ex)
			{
				// Log exception and rethrow or handle as needed
				throw new RepositoryException("An error occurred while retrieving the user.", ex);
			}
		}

		public async Task<User> GetUserByResetTokenAsync(string token)
		{
			return await _context.Users.FirstOrDefaultAsync(u => u.ResetToken == token);
		}

		public async Task<bool> IsUserAlreadyRegisteredAsync(string username, string email)
		{
			return await _context.Users.AnyAsync(u => u.Username == username || u.Email == email);
		}

		public async Task<int?> GetUserIdByUsernameAsync(string username)
		{
			return (await _context.Users.FirstOrDefaultAsync(u => u.Username == username))?.UserId;
		}
	}
}
