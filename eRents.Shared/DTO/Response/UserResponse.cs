namespace eRents.Shared.DTO.Response
{
	public class UserResponse
	{
		public int UserId { get; set; }
		public string? Username { get; set; }
		public string? Email { get; set; }
		public string FullName { get; set; }
		public byte[]? ProfilePicture { get; set; }
		public DateOnly DateOfBirth { get; set; }
		public string? Address { get; set; }
		public string? PhoneNumber { get; set; }
		public string Role { get; set; }
	}
}