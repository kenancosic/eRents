using System.ComponentModel.DataAnnotations;

namespace eRents.Shared.DTO.Requests
{
	public class UserInsertRequest
	{
		[Required]
		public string? Username { get; set; }

		[Required, EmailAddress]
		public string? Email { get; set; }

		[Required, MinLength(6)]
		public string? Password { get; set; }

		[Required]
		public string? ConfirmPassword { get; set; }

		public string? Address { get; set; }
		public DateTime DateOfBirth { get; set; }
		public string? PhoneNumber { get; set; }
		public string? Name { get; set; }
		public string? LastName { get; set; }
		[Required]
		public string Role { get; set; }
		public string? ProfilePicture { get; set; }
	}
}

