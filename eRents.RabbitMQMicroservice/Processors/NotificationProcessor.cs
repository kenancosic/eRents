using System.Text;
using Newtonsoft.Json;
using RabbitMQ.Client.Events;
using eRents.RabbitMQMicroservice.Services;
using eRents.Shared.DTOs;

namespace eRents.RabbitMQMicroservice.Processors
{
    // Unified processor for booking, review, and refund notifications
    public class NotificationProcessor
    {
        private readonly IEmailService _emailService;

        public NotificationProcessor(IEmailService emailService)
        {
            _emailService = emailService;
        }

        public async Task Process(string queueName, object sender, BasicDeliverEventArgs e)
        {
            var body = e.Body.ToArray();
            var message = Encoding.UTF8.GetString(body);

            switch (queueName)
            {
                case "bookingQueue":
                    await HandleBookingAsync(message);
                    break;
                case "reviewQueue":
                    await HandleReviewAsync(message);
                    break;
                case "refundQueue":
                    await HandleRefundAsync(message);
                    break;
                default:
                    // Unknown queue; ignore or log
                    break;
            }
        }

        private async Task HandleBookingAsync(string payload)
        {
            var booking = JsonConvert.DeserializeObject<BookingNotificationMessage>(payload);
            if (booking == null) return;

            // TODO: Replace with real recipient lookup from payload/user
            var email = new EmailMessage
            {
                Email = "user@example.com",
                Subject = "Booking Notification",
                Body = $"Your booking with ID {booking.BookingId} has been processed.",
                IsHtml = false
            };
            await _emailService.SendEmailNotificationAsync(email);
        }

        private async Task HandleReviewAsync(string payload)
        {
            var review = JsonConvert.DeserializeObject<ReviewNotificationMessage>(payload);
            if (review == null) return;

            var email = new EmailMessage
            {
                Email = "owner@example.com",
                Subject = "New Review",
                Body = $"A new review with ID {review.ReviewId} was posted for property {review.PropertyId}.",
                IsHtml = false
            };
            await _emailService.SendEmailNotificationAsync(email);
        }

        private async Task HandleRefundAsync(string payload)
        {
            var refund = JsonConvert.DeserializeObject<RefundNotificationMessage>(payload);
            if (refund == null) return;

            var email = new EmailMessage
            {
                Email = "user@example.com",
                Subject = "Refund Processed",
                Body = $"Your refund for booking {refund.BookingId} has been processed.",
                IsHtml = false
            };
            await _emailService.SendEmailNotificationAsync(email);
        }
    }
}
