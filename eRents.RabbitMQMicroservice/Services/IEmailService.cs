using eRents.Shared.Messaging;

namespace eRents.RabbitMQMicroservice.Services
{
	public interface IEmailService
	{
		void SendEmailNotification(EmailMessage message);
	}
}