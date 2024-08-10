namespace eRents.Application.DTO.Response
{
	public class UserResponse
	{
		public int UserId { get; set; }
		public string Username { get; set; }
		public string Email { get; set; }
		public string FullName { get; set; }
		public DateTime DateOfBirth { get; set; }
		public string Address { get; set; }
		public string PhoneNumber { get; set; }
		// Add any other properties you need in the response
	}
}