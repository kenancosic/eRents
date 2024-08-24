using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eRents.Domain.Entities
{
	public class UserSavedProperty
	{
		public int UserId { get; set; }
		public User User { get; set; }

		public int PropertyId { get; set; }
		public Property Property { get; set; }

		public DateTime DateSaved { get; set; }  // Optional, to track when a property was saved
	}

}
