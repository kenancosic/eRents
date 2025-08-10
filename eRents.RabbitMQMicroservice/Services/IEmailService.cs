using eRents.Shared.DTOs;
using System.Threading;
using System.Threading.Tasks;

namespace eRents.RabbitMQMicroservice.Services
{
	public interface IEmailService
	{
		Task SendEmailNotificationAsync(EmailMessage message, CancellationToken ct = default);
	}
}