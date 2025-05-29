using eRents.Shared.Messaging;
using System;
using System.Net;
using System.Net.Mail;

namespace eRents.RabbitMQMicroservice.Services
{
	public class SmtpEmailService : IEmailService
	{
		public void SendEmailNotification(EmailMessage message)
		{
			try
			{
				var smtpClient = new SmtpClient("smtp.example.com") // Use your SMTP server
				{
					Port = 587,
					Credentials = new NetworkCredential("username", "password"), // Use your credentials
					EnableSsl = true,
				};

				var mailMessage = new MailMessage
				{
					From = new MailAddress("no-reply@example.com"),
					Subject = message.Subject,
					Body = message.Body,
					IsBodyHtml = true,
				};

				mailMessage.To.Add(message.Email);

				smtpClient.Send(mailMessage);
				Console.WriteLine("Email sent successfully.");
			}
			catch (Exception ex)
			{
				Console.WriteLine($"Error sending email: {ex.Message}");
				// Handle exceptions as needed
			}
		}
	}
}
