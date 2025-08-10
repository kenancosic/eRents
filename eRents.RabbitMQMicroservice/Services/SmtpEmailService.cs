using eRents.Shared.DTOs;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using System;
using System.Net;
using System.Net.Mail;
using System.Threading;
using System.Threading.Tasks;

namespace eRents.RabbitMQMicroservice.Services
{
	public class SmtpEmailService : IEmailService, Shared.Services.IEmailService
	{
		private readonly IConfiguration _configuration;
		private readonly ILogger<SmtpEmailService> _logger;

		public SmtpEmailService(IConfiguration configuration, ILogger<SmtpEmailService> logger)
		{
			_configuration = configuration;
			_logger = logger;
		}

		public async Task SendEmailNotificationAsync(EmailMessage message, CancellationToken ct = default)
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

				using var smtpClient = new SmtpClient(smtpServer)
				{
					Port = smtpPort,
					Credentials = new NetworkCredential(smtpUsername, smtpPassword),
					EnableSsl = true,
				};

				using var mailMessage = new MailMessage
				{
					From = new MailAddress(fromEmail, fromName),
					Subject = message.Subject,
					Body = message.Body,
					IsBodyHtml = message.IsHtml,
				};

				var recipient = string.IsNullOrWhiteSpace(message.To) ? message.Email : message.To;
				mailMessage.To.Add(recipient);

				await smtpClient.SendMailAsync(mailMessage);
				_logger.LogInformation("Email sent successfully to {Email}", recipient);
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error sending email to {Email}", message.Email);
				// Handle exceptions as needed
			}
		}
	}
}
