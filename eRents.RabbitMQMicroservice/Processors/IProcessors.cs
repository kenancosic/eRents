using RabbitMQ.Client.Events;

namespace eRents.RabbitMQMicroservice.Processors
{
	public interface IBookingNotificationProcessor
	{
		void Process(string message);
	}

	public interface IReviewNotificationProcessor
	{
		void Process(object sender, BasicDeliverEventArgs e);
	}

	public interface IEmailNotificationProcessor
	{
		void Process(string message);
	}
	public interface IChatMessageProcessor
	{
		void Process(object sender, BasicDeliverEventArgs e);
	}
}
