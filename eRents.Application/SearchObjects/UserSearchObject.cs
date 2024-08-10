using eRents.Application.Shared;
using eRents.Shared.Abstracts;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eRents.Application.SearchObjects
{
	public class UserSearchObject : BaseSearchObject
	{
		public string Username { get; set; }
		public string NameFTS { get; set; }
		public string Email { get; set; }

	}
}
