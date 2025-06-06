using eRents.Shared.Messaging;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using System;
using System.Net;
using System.Net.Mail;

namespace eRents.RabbitMQMicroservice.Services
{
	public class SmtpEmailService : IEmailService
	{
		private readonly IConfiguration _configuration;
		private readonly ILogger<SmtpEmailService> _logger;

		public SmtpEmailService(IConfiguration configuration, ILogger<SmtpEmailService> logger)
		{
			_configuration = configuration;
			_logger = logger;
		}

		public void SendEmailNotification(EmailMessage message)
		{
			try
			{
				var smtpServer = _configuration["Email:SmtpServer"] ?? "smtp.gmail.com";
				var smtpPort = int.Parse(_configuration["Email:SmtpPort"] ?? "587");
				var smtpUsername = _configuration["Email:SmtpUsername"];
				var smtpPassword = _configuration["Email:SmtpPassword"];
				var fromEmail = _configuration["Email:FromEmail"] ?? "no-reply@erents.com";
				var fromName = _configuration["Email:FromName"] ?? "eRents Platform";

				if (string.IsNullOrEmpty(smtpUsername) || string.IsNullOrEmpty(smtpPassword))
				{
					_logger.LogWarning("SMTP credentials not configured. Email not sent.");
					return;
				}

				var smtpClient = new SmtpClient(smtpServer)
				{
					Port = smtpPort,
					Credentials = new NetworkCredential(smtpUsername, smtpPassword),
					EnableSsl = true,
				};

				var mailMessage = new MailMessage
				{
					From = new MailAddress(fromEmail, fromName),
					Subject = message.Subject,
					Body = message.Body,
					IsBodyHtml = true,
				};

				mailMessage.To.Add(message.Email);

				smtpClient.Send(mailMessage);
				_logger.LogInformation("Email sent successfully to {Email}", message.Email);
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error sending email to {Email}", message.Email);
				// Handle exceptions as needed
			}
		}
	}
}
