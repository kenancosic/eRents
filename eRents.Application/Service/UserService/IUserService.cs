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
		void ChangePassword(int userId, ChangePasswordRequest request);
		void ForgotPassword(string request);
		void ResetPassword(ResetPasswordRequest request);
	}
}