namespace eRents.Application.Service.MessagingService
{
	public interface IUserLookupService
	{
		Task<int> GetUserIdByUsernameAsync(string username);
		Task<string> GetUsernameByUserIdAsync(int userId);
	}
} 