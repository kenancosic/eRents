using eRents.RabbitMQMicroservice.DTO;

namespace eRents.RabbitMQMicroservice.Services
{
	public class SmtpEmailService : IEmailService
	{
		public void SendEmail(EmailMessage message)
		{
			// Implement your email sending logic here (e.g., SMTP, SendGrid, etc.)
			Console.WriteLine($"Sending email to {message.Email} with subject {message.Subject}");
		}
	}
}