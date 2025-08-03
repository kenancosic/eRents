using eRents.Domain.Shared;
using Microsoft.EntityFrameworkCore;
using eRents.Domain.Models;
using eRents.Domain.Shared.Interfaces;
using eRents.WebApi.Services;
using eRents.Features.Shared.Services;

using eRents.Features.UserManagement.Services;
using eRents.Features.PropertyManagement.Services;
using eRents.Features.FinancialManagement.Services;
using eRents.Features.RentalManagement.Services;
using eRents.Features.ReviewManagement.Services;
using eRents.RabbitMQMicroservice.Services;
using IEmailService = eRents.Shared.Services.IEmailService;
using eRents.Features.Shared.Services.LookupServices;
using eRents.Features.PropertyManagement.Services;
using eRents.Features.PropertyManagement.DTOs;
using eRents.Domain.Models;
using FluentValidation;
using eRents.Features.Core.Validation;
using eRents.Features.Core.Filters;
using eRents.Features.Core.Interfaces;
using eRents.Features.Core.Services;

namespace eRents.WebApi.Extensions;

public static class ServiceRegistrationExtensions
{
    public static void ConfigureServices(this IServiceCollection services, IConfiguration configuration)
    {
        // Database Configuration
        services.AddDbContext<ERentsContext>(options =>
            options.UseSqlServer(configuration.GetConnectionString("DefaultConnection")));

        // Unit of Work and Core Services
        services.AddScoped<IUnitOfWork, UnitOfWork>();
        services.AddScoped<ICurrentUserService, CurrentUserService>();

        // Register CRUD abstractions and validation
        services.AddCustomValidation(
            typeof(ServiceRegistrationExtensions).Assembly,
            typeof(BaseValidator<>).Assembly
        );

        // Register base services
        services.AddScoped(typeof(IReadService<,,>), typeof(BaseReadService<,,>));
        services.AddScoped(typeof(ICrudService<,,,>), typeof(BaseCrudService<,,,>));

        // Shared Feature Services (cross-cutting concerns)
        services.AddScoped<IImageService, ImageService>();
        services.AddScoped<IMessagingService, MessagingService>();
        services.AddScoped<INotificationService, NotificationService>();
        services.AddScoped<IEmailService, SmtpEmailService>();
        
        // Lookup Services
        services.AddScoped<AmenityLookupService>();
        // IRecommendationService removed - enterprise ML feature simplified for academic thesis
        // IAvailabilityService removed - complex availability management simplified to Property.Status enum
        // IContractExpirationService removed - enterprise contract management simplified to basic date queries
        // ILeaseCalculationService removed - complex lease calculations simplified to basic DateOnly arithmetic

        // Feature-Specific Services
        RegisterUserManagementServices(services);
        RegisterPropertyManagementServices(services);
        RegisterBookingManagementServices(services);
        RegisterFinancialManagementServices(services);
        RegisterRentalManagementServices(services);
        RegisterTenantManagementServices(services);
        RegisterReviewManagementServices(services);
    }

    private static void RegisterUserManagementServices(IServiceCollection services)
    {
        // Consolidated service handles both user and tenant management
        services.AddScoped<IUserService>(provider =>
        {
            var context = provider.GetRequiredService<ERentsContext>();
            var unitOfWork = provider.GetRequiredService<IUnitOfWork>();
            var currentUserService = provider.GetRequiredService<ICurrentUserService>();
            var configuration = provider.GetRequiredService<IConfiguration>();
            var logger = provider.GetRequiredService<ILogger<UserService>>();
            var emailService = provider.GetRequiredService<IEmailService>();

            return new UserService(context, unitOfWork, currentUserService, configuration, logger, emailService);
        });
        services.AddScoped<IAuthorizationService, AuthorizationService>();
    }

    private static void RegisterPropertyManagementServices(IServiceCollection services)
    {
        services.AddScoped<IPropertyService, PropertyService>();
        // Keep the old interface registration for backward compatibility during transition
        services.AddScoped<IPropertyManagementService, PropertyService>();
    }

    private static void RegisterBookingManagementServices(IServiceCollection services)
    {
        // Booking services now handled by consolidated RentalService
        // services.AddScoped<IBookingService, BookingService>(); // Removed - consolidated into RentalService
    }

    private static void RegisterFinancialManagementServices(IServiceCollection services)
    {
        services.AddScoped<IPaymentService, PaymentService>();
    }


    private static void RegisterRentalManagementServices(IServiceCollection services)
    {
        services.AddScoped<IRentalService, RentalService>();
    }

    private static void RegisterTenantManagementServices(IServiceCollection services)
    {
    }

    private static void RegisterReviewManagementServices(IServiceCollection services)
    {
        services.AddScoped<IReviewService, ReviewService>();
    }
} 