using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using eRents.Domain.Models;
using eRents.Features.PaymentManagement.Models;

namespace eRents.Features.PaymentManagement.Services;

public interface ISubscriptionService
{
    Task<Subscription> CreateSubscriptionAsync(int tenantId, int propertyId, int bookingId, 
        decimal monthlyAmount, DateOnly startDate, DateOnly? endDate);
    Task<Payment> ProcessMonthlyPaymentAsync(int subscriptionId);
    Task<IEnumerable<Subscription>> GetDueSubscriptionsAsync();
    Task CancelSubscriptionAsync(int subscriptionId);
    Task PauseSubscriptionAsync(int subscriptionId);
    Task ResumeSubscriptionAsync(int subscriptionId);
}
