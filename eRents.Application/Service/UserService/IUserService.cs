using eRents.Application.DTO.Requests;
using eRents.Application.DTO.Response;
using eRents.Application.SearchObjects;
using eRents.Application.Shared;

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