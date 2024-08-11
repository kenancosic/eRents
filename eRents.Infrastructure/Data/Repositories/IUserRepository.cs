using eRents.Domain.Entities;
using eRents.Infrastructure.Data.Shared;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eRents.Infrastructure.Data.Repositories
{
	public interface IUserRepository : IBaseRepository<User>
	{
		Task<User> GetByUsernameAsync(string username);
		Task<User> GetByEmailAsync(string email);
		Task<bool> UserExistsAsync(string username, string email);
	}
}
