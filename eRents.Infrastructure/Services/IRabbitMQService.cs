using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eRents.Infrastructure.Services
{
	public interface IRabbitMQService
	{
		Task PublishMessageAsync(string queueName, object message);
	}

}
