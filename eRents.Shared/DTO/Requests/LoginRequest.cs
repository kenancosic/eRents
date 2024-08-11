namespace eRents.Shared.DTO.Requests
{
	public class LoginRequest
	{
		public string UsernameOrEmail { get; set; }  // or Email if you allow both for login
		public string Password { get; set; }
	}
}
