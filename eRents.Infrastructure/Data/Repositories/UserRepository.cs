using eRents.Domain.Entities;
using eRents.Infrastructure.Entities;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eRents.Infrastructure.Data.Repositories
{
	public class UserRepository : IUserRepository
	{
		private readonly ERentsContext _context;

		public UserRepository(ERentsContext context)
		{
			_context = context;
		}

		public async Task<User> GetByIdAsync(int id)
		{
			return await _context.Users.FindAsync(id);
		}

		public async Task<IEnumerable<User>> GetAllAsync()
		{
			return await _context.Users.ToListAsync();
		}

		public async Task AddAsync(User user)
		{
			await _context.Users.AddAsync(user);
			await _context.SaveChangesAsync();
		}

		public async Task UpdateAsync(User user)
		{
			_context.Users.Update(user);
			await _context.SaveChangesAsync();
		}

		public async Task DeleteAsync(int id)
		{
			var user = await _context.Users.FindAsync(id);
			if (user != null)
			{
				_context.Users.Remove(user);
				await _context.SaveChangesAsync();
			}
		}

		public async Task<User> GetByUsernameAsync(string username)
		{
			return await _context.Users
					.FirstOrDefaultAsync(u => u.Username == username);
		}

		public async Task<User> GetByEmailAsync(string email)
		{
			return await _context.Users
					.FirstOrDefaultAsync(u => u.Email == email);
		}
		public async Task<bool> UserExistsAsync(string username, string email)
		{
			return await _context.Users.AnyAsync(u => u.Username == username || u.Email == email);
		}
	}
}
