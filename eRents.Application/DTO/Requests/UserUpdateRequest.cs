using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eRents.Application.DTO.Requests
{
	public class UserUpdateRequest
	{
		public string Address { get; set; }
		public string PhoneNumber { get; set; }
		public string ProfilePicture { get; set; }
	}
}
