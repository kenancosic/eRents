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
		public string? Status { get; set; }
		public string? PaymentReference { get; set; }
		public string ApprovalUrl { get; set; }
	}
}
