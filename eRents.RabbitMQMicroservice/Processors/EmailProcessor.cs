using eRents.RabbitMQMicroservice.Services;
using eRents.Shared.DTOs;
using Newtonsoft.Json;
using System.Threading.Tasks;

namespace eRents.RabbitMQMicroservice.Processors
{
	public class EmailProcessor
	{
		private readonly IEmailService _emailService;

		public EmailProcessor(IEmailService emailService)
		{
			_emailService = emailService;
		}

		public async Task Process(string message)
		{
			var emailMessage = JsonConvert.DeserializeObject<EmailMessage>(message);
			await _emailService.SendEmailNotificationAsync(emailMessage);
		}
	}

}
