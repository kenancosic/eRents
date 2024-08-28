namespace eRents.Shared.DTO.Requests
{
	public class UserUpdateRequest
	{
		public string? Address { get; set; }
		public string? PhoneNumber { get; set; }
		public byte[]? ProfilePicture { get; set; }
		public string? Name { get; set; }  // New field
		public string? LastName { get; set; }  // New field
	}
}
