using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eRents.RabbitMQMicroservice.DTO
{
	public class EmailMessage
	{
		public string Email { get; set; }
		public string Subject { get; set; }
		public string Body { get; set; }
	}
}
