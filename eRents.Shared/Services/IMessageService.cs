using eRents.Shared.DTOs;

namespace eRents.Shared.Services
{
    public interface IMessageService
    {
        void HandleUserMessage(UserMessage message);
    }
} 