using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eRents.Shared.DTO
{
	public class ReviewNotificationMessage
	{
		public int PropertyId { get; set; }
		public int ReviewId { get; set; }
		public string? Message { get; set; }
	}
}
