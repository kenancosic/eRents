using System;

namespace eRents.Shared.DTO.Requests
{
	public class UserUpdateRequest
	{
		public string? FirstName { get; set; }
		public string? LastName { get; set; }
		public int? ProfileImageId { get; set; }
		public AddressDetailDto? AddressDetail { get; set; }
		public DateTime? UpdatedAt { get; set; }
		public bool? IsPaypalLinked { get; set; }
		public string? PaypalUserIdentifier { get; set; }
	}
}
