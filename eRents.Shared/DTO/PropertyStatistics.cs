using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eRents.Shared.DTO
{
	public class PropertyStatistics
	{
		public int PropertyId { get; set; }
		public string? PropertyName { get; set; }
		public decimal TotalRevenue { get; set; }
		public int NumberOfBookings { get; set; }
		public int NumberOfTenants { get; set; }
		public decimal AverageRating { get; set; }
		public int NumberOfReviews { get; set; }
	}
}
