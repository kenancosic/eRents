﻿using eRents.Domain.Models;
using eRents.Domain.Shared;

namespace eRents.Domain.Repositories
{
	public interface IUserRepository : IBaseRepository<User>
	{
		Task<User> GetByUsernameAsync(string username);
		Task<User> GetByEmailAsync(string email);
		Task<User> GetUserByUsernameOrEmailAsync(string usernameOrEmail);
		Task<User> GetUserByResetTokenAsync(string token);
		Task<bool> IsUserAlreadyRegisteredAsync(string username, string email);
		Task<int?> GetUserIdByUsernameAsync(string username);
	}
}
