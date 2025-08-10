using eRents.Shared.DTOs;
using System.Threading;
using System.Threading.Tasks;

namespace eRents.Shared.Services
{
    public interface IEmailService
    {
        Task SendEmailNotificationAsync(EmailMessage message, CancellationToken ct = default);
    }
}