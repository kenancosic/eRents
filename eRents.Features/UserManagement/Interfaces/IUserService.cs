using System.Threading.Tasks;
using eRents.Domain.Models;
using eRents.Features.Core;
using eRents.Features.UserManagement.Models;

namespace eRents.Features.UserManagement.Interfaces;

public interface IUserService : ICrudService<User, UserRequest, UserResponse, UserSearch>
{
    Task<bool> ChangePasswordAsync(int userId, string oldPassword, string newPassword);
}
