using eRents.Domain.Entities;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eRents.Infrastructure.Data.Repositories
{
	public interface IUserRepository
	{
		Task<User> GetByIdAsync(int id);
		Task<IEnumerable<User>> GetAllAsync();
		Task AddAsync(User user);
		Task UpdateAsync(User user);
		Task DeleteAsync(int id);
		Task<User> GetByUsernameAsync(string username);
		Task<User> GetByEmailAsync(string email);
		Task<bool> UserExistsAsync(string username, string email);

	}
}
