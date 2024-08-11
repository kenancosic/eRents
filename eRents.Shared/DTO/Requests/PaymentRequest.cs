using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eRents.Shared.DTO.Requests
{
	public class PaymentRequest
	{
		public int BookingId { get; set; }
		public decimal Amount { get; set; }
		public string? PaymentMethod { get; set; }  // e.g., Credit Card, PayPal
	}
}
