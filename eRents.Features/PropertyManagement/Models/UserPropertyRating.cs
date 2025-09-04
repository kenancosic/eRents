using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eRents.Features.PropertyManagement.Models
{
	public class UserPropertyRating
	{
		public int UserId { get; set; }
		public int PropertyId { get; set; }
		public float Rating { get; set; }
	}
}
