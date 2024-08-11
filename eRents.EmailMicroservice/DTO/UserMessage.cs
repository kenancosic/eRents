using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eRents.RabbitMQMicroservice.DTO
{
	public class UserMessage
	{
		public string SenderEmail { get; set; }
		public string RecipientEmail { get; set; }
		public string Subject { get; set; }
		public string Body { get; set; }
	}
}
