using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eRents.Shared.SearchObjects
{
	public class BookingSearchObject : BaseSearchObject
	{
		public int? PropertyId { get; set; }
		public int? UserId { get; set; }
		public DateTime? StartDate { get; set; }
		public DateTime? EndDate { get; set; }
		public string Status { get; set; }
	}
}
