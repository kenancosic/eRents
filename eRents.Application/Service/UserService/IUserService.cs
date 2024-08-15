using eRents.Application.Shared;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Shared.SearchObjects;

namespace eRents.Application.Service.UserService
{
	public interface IUserService : ICRUDService<UserResponse, UserSearchObject, UserInsertRequest, UserUpdateRequest>
	{
		Task<UserResponse> LoginAsync(string username, string password);
		Task<UserResponse> RegisterAsync(UserInsertRequest request);
		Task ChangePasswordAsync(int userId, ChangePasswordRequest request);
		Task ForgotPasswordAsync(string email);
		Task ResetPasswordAsync(ResetPasswordRequest request);
	}
}
