using eRents.Shared.DTOs;

namespace eRents.RabbitMQMicroservice.Services
{
	public interface IEmailService
	{
		void SendEmailNotification(EmailMessage message);
	}
}