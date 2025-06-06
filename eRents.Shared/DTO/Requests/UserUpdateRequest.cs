using System;
using eRents.Shared.DTO.Base;

namespace eRents.Shared.DTO.Requests
{
	public class UserUpdateRequest : BaseUpdateRequest
	{
		public string? FirstName { get; set; }
		public string? LastName { get; set; }
		public string? PhoneNumber { get; set; }
		public int? ProfileImageId { get; set; }
		public AddressRequest? Address { get; set; }
		public DateTime? UpdatedAt { get; set; }
		public bool? IsPaypalLinked { get; set; }
		public string? PaypalUserIdentifier { get; set; }
	}
}
