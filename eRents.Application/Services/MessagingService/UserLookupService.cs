using eRents.Domain.Repositories;

namespace eRents.Application.Services.MessagingService
{
	public class UserLookupService : IUserLookupService
	{
		private readonly IUserRepository _userRepository;

		public UserLookupService(IUserRepository userRepository)
		{
			_userRepository = userRepository;
		}

		public async Task<int> GetUserIdByUsernameAsync(string username)
		{
			// Handle the special case where username is in format "user_{id}"
			if (username.StartsWith("user_") && int.TryParse(username.Substring(5), out var userId))
			{
				return userId;
			}

			var user = await _userRepository.GetByUsernameAsync(username);
			return user?.UserId ?? 0;
		}

		public async Task<string> GetUsernameByUserIdAsync(int userId)
		{
			var user = await _userRepository.GetByIdAsync(userId);
			return user?.Username ?? $"user_{userId}";
		}
	}
} 