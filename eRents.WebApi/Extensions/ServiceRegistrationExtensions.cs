using eRents.Domain.Shared;
using Microsoft.EntityFrameworkCore;
using eRents.Domain.Models;
using eRents.Domain.Shared.Interfaces;
using eRents.WebApi.Services;
using eRents.Features.Shared.Services;

// Features Services Registration
using eRents.Features.UserManagement.Services;
using eRents.Features.PropertyManagement.Services;
using eRents.Features.BookingManagement.Services;
using eRents.Features.FinancialManagement.Services;
using eRents.Features.MaintenanceManagement.Services;
using eRents.Features.RentalManagement.Services;
using eRents.Features.TenantManagement.Services;
using eRents.Features.ReviewManagement.Services;

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

        // Shared Feature Services (cross-cutting concerns)
        services.AddScoped<IAvailabilityService, AvailabilityService>();
        services.AddScoped<IContractExpirationService, ContractExpirationService>();
        services.AddScoped<IImageService, ImageService>();
        services.AddScoped<ILeaseCalculationService, LeaseCalculationService>();
        services.AddScoped<IMessagingService, MessagingService>();
        services.AddScoped<INotificationService, NotificationService>();
        services.AddScoped<IRecommendationService, RecommendationService>();

        // Feature-Specific Services
        RegisterUserManagementServices(services);
        RegisterPropertyManagementServices(services);
        RegisterBookingManagementServices(services);
        RegisterFinancialManagementServices(services);
        RegisterMaintenanceManagementServices(services);
        RegisterRentalManagementServices(services);
        RegisterTenantManagementServices(services);
        RegisterReviewManagementServices(services);
    }

    private static void RegisterUserManagementServices(IServiceCollection services)
    {
        services.AddScoped<IUserService, UserService>();
        services.AddScoped<IAuthorizationService, AuthorizationService>();
    }

    private static void RegisterPropertyManagementServices(IServiceCollection services)
    {
        services.AddScoped<IPropertyManagementService, PropertyService>();
        services.AddScoped<IUserSavedPropertiesService, UserSavedPropertiesService>();
    }

    private static void RegisterBookingManagementServices(IServiceCollection services)
    {
        services.AddScoped<IBookingService, BookingService>();
    }

    private static void RegisterFinancialManagementServices(IServiceCollection services)
    {
        services.AddScoped<IPaymentService, PaymentService>();
        services.AddScoped<IStatisticsService, StatisticsService>();
        services.AddScoped<IReportService, ReportService>();
    }

    private static void RegisterMaintenanceManagementServices(IServiceCollection services)
    {
        services.AddScoped<IMaintenanceService, MaintenanceService>();
    }

    private static void RegisterRentalManagementServices(IServiceCollection services)
    {
        services.AddScoped<IRentalRequestService, RentalRequestService>();
    }

    private static void RegisterTenantManagementServices(IServiceCollection services)
    {
        services.AddScoped<ITenantService, TenantService>();
    }

    private static void RegisterReviewManagementServices(IServiceCollection services)
    {
        services.AddScoped<IReviewService, ReviewService>();
    }
} 