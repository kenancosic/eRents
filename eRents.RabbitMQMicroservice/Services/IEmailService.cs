using eRents.Shared.DTO;

namespace eRents.RabbitMQMicroservice.Services
{
	public interface IEmailService
	{
		void SendEmailNotification(EmailMessage message);
	}
}