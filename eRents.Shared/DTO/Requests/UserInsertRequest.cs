using System;
using System.ComponentModel.DataAnnotations;
using eRents.Shared.DTO.Base;

namespace eRents.Shared.DTO.Requests
{
	public class UserInsertRequest : BaseInsertRequest
	{
		[Required]
		public string? Username { get; set; }

		[Required, EmailAddress]
		public string? Email { get; set; }

		[Required, MinLength(6)]
		public string? Password { get; set; }

		[Required]
		public string? ConfirmPassword { get; set; }

		public string? FirstName { get; set; }
		public string? LastName { get; set; }
		public int? ProfileImageId { get; set; }
		public AddressDetailRequest? AddressDetail { get; set; }
		public DateTime? CreatedAt { get; set; }
		public DateTime? UpdatedAt { get; set; }
		public bool? IsPaypalLinked { get; set; }
		public string? PaypalUserIdentifier { get; set; }
		[Required]
		public string Role { get; set; }
	}
}

