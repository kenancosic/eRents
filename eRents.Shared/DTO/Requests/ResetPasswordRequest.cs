namespace eRents.Shared.DTO.Requests
{
	public class ResetPasswordRequest
	{
		public string Token { get; set; }       // The token sent to the user's email
		public string NewPassword { get; set; }
		public string ConfirmPassword { get; set; }
	}
}
