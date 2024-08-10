using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eRents.Application.DTO.Requests
{
	public class LoginRequest
	{
		public string UsernameOrEmail { get; set; }  // or Email if you allow both for login
		public string Password { get; set; }
	}
}
