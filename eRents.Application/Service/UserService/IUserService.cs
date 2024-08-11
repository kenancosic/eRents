using eRents.Application.Shared;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Shared.SearchObjects;

namespace eRents.Application.Service.UserService
{
	public interface IUserService : ICRUDService<UserResponse, UserSearchObject, UserInsertRequest, UserUpdateRequest>
	{
		UserResponse Login(string username, string password);
		UserResponse Register(UserInsertRequest request);
		void ChangePassword(int userId, ChangePasswordRequest request);
		void ForgotPassword(string request);
		void ResetPassword(ResetPasswordRequest request);
	}
}