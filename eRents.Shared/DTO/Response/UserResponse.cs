using System;
using eRents.Shared.DTO.Base;

namespace eRents.Shared.DTO.Response
{
	public class UserResponse : BaseResponse
	{
		public string? Username { get; set; }
		public string? Email { get; set; }
		public string? FirstName { get; set; }
		public string? LastName { get; set; }
		public string? FullName { get; set; }
		public int? ProfileImageId { get; set; }
		public string? PhoneNumber { get; set; }
		public string Role { get; set; }
		public AddressDetailResponse? AddressDetail { get; set; }
		public bool IsPaypalLinked { get; set; }
		public string? PaypalUserIdentifier { get; set; }
	}
}