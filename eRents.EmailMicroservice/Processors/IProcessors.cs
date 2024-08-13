using RabbitMQ.Client.Events;

namespace eRents.RabbitMQMicroservice.Processors
{
	public interface IBookingNotificationProcessor
	{
		void Process(object sender, BasicDeliverEventArgs e);
	}

	public interface IReviewNotificationProcessor
	{
		void Process(object sender, BasicDeliverEventArgs e);
	}

	public interface IEmailNotificationProcessor
	{
		void Process(object sender, BasicDeliverEventArgs e);
	}
}
