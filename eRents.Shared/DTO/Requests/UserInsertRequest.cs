namespace eRents.Shared.DTO.Requests
{
	public class UserInsertRequest
	{
		public string? Username { get; set; }
		public string? Email { get; set; }
		public string? Password { get; set; }
		public string? ConfirmPassword { get; set; }
		public string? Address { get; set; }
		public DateTime DateOfBirth { get; set; }
		public string? PhoneNumber { get; set; }
		public string? Name { get; set; }
		public string? LastName { get; set; }
		public string Role { get; set; }
		public byte[]? ProfilePicture { get; set; }
	}
}

