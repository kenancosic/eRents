using RabbitMQ.Client.Events;
using System.Threading.Tasks;

namespace eRents.RabbitMQMicroservice.Processors
{
	public interface IBookingNotificationProcessor
	{
		Task Process(string message);
	}

	public interface IReviewNotificationProcessor
	{
		Task Process(object sender, BasicDeliverEventArgs e);
	}

	public interface IEmailNotificationProcessor
	{
		Task Process(string message);
	}
	
	public interface IChatMessageProcessor
	{
		void Process(object sender, BasicDeliverEventArgs e);
	}
	
	public interface IRefundNotificationProcessor
	{
		Task Process(string message);
	}
}
