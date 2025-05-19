using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace eRents.Shared.Services
{
    public interface IRabbitMQService : IDisposable
    {
        Task PublishMessageAsync(string queueName, object message);
        Task SubscribeAsync(string queueName, Func<string, Task> onMessageReceived);
        void DeclareQueue(string queueName, bool durable = true, bool exclusive = false, bool autoDelete = false, IDictionary<string, object>? arguments = null);
    }
} 