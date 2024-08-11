using eRents.RabbitMQMicroservice.Services;
using eRents.Shared.DTO;
using Newtonsoft.Json;

namespace eRents.RabbitMQMicroservice.Processors
{
	public class EmailProcessor
	{
		private readonly IEmailService _emailService;

		public EmailProcessor(IEmailService emailService)
		{
			_emailService = emailService;
		}

		public void Process(string message)
		{
			var emailMessage = JsonConvert.DeserializeObject<EmailMessage>(message);
			_emailService.SendEmail(emailMessage);
		}
	}
}
