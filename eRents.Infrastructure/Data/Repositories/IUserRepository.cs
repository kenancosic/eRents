using eRents.Domain.Entities;
using eRents.Infrastructure.Data.Shared;

namespace eRents.Infrastructure.Data.Repositories
{
	public interface IUserRepository : IBaseRepository<User>
	{
		Task<User> GetByUsernameAsync(string username);
		Task<User> GetByEmailAsync(string email);
		User GetUserByUsernameOrEmail(string usernameOrEmail);
		Task<User> GetUserByResetToken(string token);
		Task<bool> IsUserAlreadyRegistered(string username, string email);
		Task<User> GetUserByUsernameOrEmailAsync(string usernameOrEmail);
	}
}