using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eRents.Shared.DTO.Response
{
	public class PaymentResponse
	{
		public int PaymentId { get; set; }
		public string Status { get; set; }  // e.g., Success, Pending, Failed
		public string PaymentReference { get; set; }  // Reference from payment gateway
	}
}
