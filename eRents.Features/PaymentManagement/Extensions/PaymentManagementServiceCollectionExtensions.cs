using Microsoft.Extensions.DependencyInjection;
using FluentValidation;
using eRents.Domain.Models;
using eRents.Features.Core;
using eRents.Features.PaymentManagement.Models;
using eRents.Features.PaymentManagement.Services;
using eRents.Features.PaymentManagement.Validators;

namespace eRents.Features.PaymentManagement.Extensions;

/// <summary>
/// Extension methods for registering PaymentManagement services and validators.
/// </summary>
public static class PaymentManagementServiceCollectionExtensions
{
    /// <summary>
    /// Registers PaymentManagement feature services, CRUD mappings, and validators.
    /// </summary>
    public static IServiceCollection AddPaymentManagement(this IServiceCollection services)
    {
        // Concrete service
        services.AddScoped<PaymentService>();

        // Generic CRUD mapping
        services.AddScoped<ICrudService<Payment, PaymentRequest, PaymentResponse, PaymentSearch>, PaymentService>();

        // PayPal payment service
        services.AddScoped<IPayPalPaymentService, PayPalPaymentService>();

        // Subscription service
        services.AddScoped<ISubscriptionService, SubscriptionService>();

        // Validators
        services.AddScoped<IValidator<PaymentRequest>, PaymentRequestValidator>();

        return services;
    }
}
