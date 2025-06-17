namespace eRents.Application.Services.MessagingService
{
	public interface IUserLookupService
	{
		Task<int> GetUserIdByUsernameAsync(string username);
		Task<string> GetUsernameByUserIdAsync(int userId);
	}
} 