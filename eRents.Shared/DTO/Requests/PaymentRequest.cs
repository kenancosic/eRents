using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eRents.Shared.DTO.Requests
{
	public class PaymentRequest
	{
		public int? BookingId { get; set; }  // Nullable since it might not exist during creation
		public int PropertyId { get; set; }  // Property being booked
		public decimal Amount { get; set; }
		public string PaymentMethod { get; set; } = "PayPal";  // Default to PayPal
		public string Currency { get; set; } = "BAM";  // Base currency
	}
}
