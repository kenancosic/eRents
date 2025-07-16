using eRents.Shared.DTOs;

namespace eRents.Shared.Services
{
    public interface IEmailService
    {
        void SendEmailNotification(EmailMessage message);
    }
} 