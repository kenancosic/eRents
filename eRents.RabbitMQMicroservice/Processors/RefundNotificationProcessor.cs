using eRents.RabbitMQMicroservice.Services;
using eRents.Shared.DTOs;
using System;
using System.Text.Json;
using System.Threading.Tasks;

namespace eRents.RabbitMQMicroservice.Processors
{
    public class RefundNotificationProcessor : IRefundNotificationProcessor
    {
        private readonly RabbitMQService _rabbitMQService;
        private readonly IEmailService _emailService;

        public RefundNotificationProcessor(RabbitMQService rabbitMQService, IEmailService emailService)
        {
            _rabbitMQService = rabbitMQService;
            _emailService = emailService;
        }

        public async Task Process(string message)
        {
            try
            {
                var refundNotification = JsonSerializer.Deserialize<RefundNotificationMessage>(message);
                if (refundNotification == null) return;

                // Create email message for refund notification
                var emailMessage = new EmailMessage
                {
                    To = refundNotification.UserId, // In a real implementation, this would be converted to an actual email address
                    Subject = "Booking Refund Notification",
                    Body = $@"<p>Dear User,</p>
<p>{refundNotification.Message}</p>
<p><strong>Refund Details:</strong></p>
<ul>
<li>Booking ID: {refundNotification.BookingId}</li>
<li>Amount: {refundNotification.Amount} {refundNotification.Currency}</li>
<li>Reason: {refundNotification.Reason}</li>
</ul>
<p>The refund will be processed to your original payment method within 5-7 business days.</p>
<p>Best regards,<br/>eRents Team</p>",
                    IsHtml = true
                };

                // Publish email message to email queue
                await _rabbitMQService.PublishMessageAsync(emailMessage, "emailQueue");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error processing refund notification: {ex.Message}");
            }
        }
    }
}
