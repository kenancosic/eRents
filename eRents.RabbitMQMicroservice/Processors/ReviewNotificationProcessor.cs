using eRents.RabbitMQMicroservice.Services;
using eRents.Shared.DTOs;
using Newtonsoft.Json;
using RabbitMQ.Client.Events;
using System.Text;
using System.Threading.Tasks;

namespace eRents.RabbitMQMicroservice.Processors
{
	public class ReviewNotificationProcessor : IReviewNotificationProcessor
	{
		private readonly IEmailService _emailService;

		public ReviewNotificationProcessor(IEmailService emailService)
		{
			_emailService = emailService;
		}

		public async Task Process(object sender, BasicDeliverEventArgs e)
		{
			var body = e.Body.ToArray();
			var message = Encoding.UTF8.GetString(body);
			var reviewNotification = JsonConvert.DeserializeObject<ReviewNotificationMessage>(message);

			Console.WriteLine($"Processing review notification for Property ID: {reviewNotification.PropertyId}, Review ID: {reviewNotification.ReviewId}");

			var emailMessage = new EmailMessage
			{
				Email = "owner@example.com", // Retrieve from property or user data
				Subject = "New Review Notification",
				Body = $"A new review with ID {reviewNotification.ReviewId} has been posted for your property with ID {reviewNotification.PropertyId}."
			};
			await _emailService.SendEmailNotificationAsync(emailMessage);
		}

	}
}
