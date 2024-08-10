using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eRents.Application.DTO.Requests
{
	public class UserInsertRequest
	{
		public string Username { get; set; }
		public string Email { get; set; }
		public string Password { get; set; }
		public string ConfirmPassword { get; set; }
		public string Address { get; set; }
		public DateTime DateOfBirth { get; set; }
		public string PhoneNumber { get; set; }
	}
}

