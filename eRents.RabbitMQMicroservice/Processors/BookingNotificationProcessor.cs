using eRents.RabbitMQMicroservice.Services;
using eRents.Shared.DTO;
using Newtonsoft.Json;

namespace eRents.RabbitMQMicroservice.Processors
{
	public class BookingNotificationProcessor : IBookingNotificationProcessor
	{
		private readonly IEmailService _emailService;

		public BookingNotificationProcessor(IEmailService emailService)
		{
			_emailService = emailService;
		}

		public async Task Process(string message)
		{
			try
			{
				var bookingNotification = JsonConvert.DeserializeObject<BookingNotificationMessage>(message);
				Console.WriteLine($"Processing booking notification for Booking ID: {bookingNotification.BookingId}");

				var emailMessage = new EmailMessage
				{
					Email = "user@example.com", // Retrieve from booking or user data
					Subject = "Booking Confirmation",
					Body = $"Your booking with ID {bookingNotification.BookingId} has been confirmed."
				};
				_emailService.SendEmailNotification(emailMessage);
			}
			catch (Exception ex)
			{
				Console.WriteLine($"Error processing booking notification: {ex.Message}");
				// Implement retry logic or dead-letter queuing as necessary
			}
		}
	}
}
