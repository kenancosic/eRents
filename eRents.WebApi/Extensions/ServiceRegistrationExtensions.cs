using eRents.Application.Service.BookingService;
using eRents.Application.Service.ContractExpirationService;
using eRents.Application.Service.ImageService;
using eRents.Application.Service.MaintenanceService;
using eRents.Application.Service.MessagingService;
using eRents.Application.Service.NotificationService;
using eRents.Application.Service.PaymentService;
using eRents.Application.Service.PropertyService;
using eRents.Application.Service.RentalRequestService;
using eRents.Application.Service.ReportService;
using eRents.Application.Service.ReviewService;
using eRents.Application.Service.RentalCoordinatorService;
using eRents.Application.Service.StatisticsService;
using eRents.Application.Service.TenantService;
using eRents.Application.Service.UserService;
using eRents.Application.Service.AvailabilityService;
using eRents.Application.Service.LeaseCalculationService;
using eRents.Domain.Models;
using eRents.Domain.Repositories;
using eRents.Domain.Shared;
using eRents.RabbitMQMicroservice.Services;
using eRents.Shared.Services;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using eRents.WebApi.Extensions;
using eRents.WebAPI.Filters;
using Microsoft.EntityFrameworkCore;
using Microsoft.OpenApi.Models;
using Microsoft.Extensions.Logging;
using eRents.WebApi.Hubs;

namespace eRents.WebApi.Extensions
{
    /// <summary>
    /// Extension methods for organizing service registration in a clean, maintainable way
    /// Part of Phase 2 enhancement to reduce Program.cs complexity
    /// </summary>
    public static class ServiceRegistrationExtensions
    {
        /// <summary>
        /// Registers all repository dependencies for the eRents application
        /// Organized by architectural layer for better maintainability
        /// </summary>
        public static IServiceCollection AddERentsRepositories(this IServiceCollection services)
        {
            // Core entity repositories with concurrency control
            services.AddTransient<IUserRepository, UserRepository>();
            services.AddTransient<IPropertyRepository, PropertyRepository>();
            services.AddTransient<IBookingRepository, BookingRepository>();
            services.AddTransient<IReviewRepository, ReviewRepository>();
            services.AddTransient<IMaintenanceRepository, MaintenanceRepository>();
            services.AddTransient<ITenantPreferenceRepository, TenantPreferenceRepository>();
            
            // Register concurrent repository interfaces ONLY for entities that actually implement IConcurrentRepository
            // These repositories inherit from ConcurrentBaseRepository
            services.AddTransient<IConcurrentRepository<MaintenanceIssue>, MaintenanceRepository>();
            services.AddTransient<IConcurrentRepository<TenantPreference>, TenantPreferenceRepository>();
            
            // Phase 3 concurrent repositories
            services.AddTransient<IConcurrentRepository<Message>, MessageRepository>();
            services.AddTransient<IConcurrentRepository<Tenant>, TenantRepository>();
            services.AddTransient<IConcurrentRepository<Image>, ImageRepository>();
            
            // Phase 4 concurrent repositories
            services.AddTransient<IConcurrentRepository<Payment>, PaymentRepository>();
            services.AddTransient<IConcurrentRepository<Amenity>, AmenityRepository>();
            
            // Repository interfaces for Phase 3 entities
            services.AddTransient<IImageRepository, ImageRepository>();
            services.AddTransient<ITenantRepository, TenantRepository>();
            services.AddTransient<IMessageRepository, MessageRepository>();
            
            // Repository interfaces for Phase 4 entities
            services.AddTransient<IPaymentRepository, PaymentRepository>();
            services.AddTransient<IAmenityRepository, AmenityRepository>();
            
            // ✅ NEW: RentalRequest repository for dual rental system
            services.AddTransient<IRentalRequestRepository, RentalRequestRepository>();
            
            // Generic base repository for UserType (existing pattern)
            services.AddTransient<IBaseRepository<UserType>, BaseRepository<UserType>>();
            
            return services;
        }
        
        /// <summary>
        /// Registers all business service dependencies for the eRents application
        /// Grouped by functional domain for logical organization
        /// </summary>
        public static IServiceCollection AddERentsBusinessServices(this IServiceCollection services)
        {
            // Core business services
            services.AddTransient<IUserService, UserService>();
            services.AddTransient<IPropertyService, PropertyService>();
            // Updated BookingService with PropertyRepository and TenantRepository dependencies for dual rental system
            services.AddTransient<IBookingService, BookingService>();
            services.AddTransient<IReviewService, ReviewService>();
            services.AddTransient<IMaintenanceService, MaintenanceService>();
            services.AddTransient<ITenantService, TenantService>();
            
            // Specialized services
            services.AddTransient<IImageService, ImageService>();
            services.AddTransient<IUserLookupService, UserLookupService>();
            services.AddTransient<IMessageHandlerService, MessageHandlerService>();
            services.AddTransient<IStatisticsService, StatisticsService>();
            services.AddTransient<IReportService, ReportService>();
            
            			// ✅ BookingCalculationService removed - calculations now done inline
            
            // Real-time messaging service
            services.AddTransient<IRealTimeMessagingService, RealTimeMessagingService<ChatHub>>();
            
            // ✅ NEW: RentalRequest service for dual rental system
            services.AddTransient<IRentalRequestService, RentalRequestService>();
            
            // ✅ Phase 3: RentalCoordinatorService - Clean architecture replacing SimpleRentalService
            services.AddTransient<IRentalCoordinatorService, RentalCoordinatorService>();
            
            // ✅ NEW: Notification service for contract expiration notifications
            services.AddTransient<INotificationService, NotificationService>();
            
            // ✅ NEW: Contract expiration background service
            services.AddHostedService<ContractExpirationService>();
            
            // ✅ Phase 2: Centralized availability and lease calculation services
            services.AddTransient<IAvailabilityService, AvailabilityService>();
            services.AddTransient<ILeaseCalculationService, LeaseCalculationService>();
            
            // TODO: Future Enhancement - Add ITenantMatchingService for ML-based recommendations
            
            return services;
        }
        
        /// <summary>
        /// Registers all infrastructure and external service dependencies
        /// Includes HTTP services, message queues, and payment processing
        /// </summary>
        public static IServiceCollection AddERentsInfrastructure(this IServiceCollection services, IConfiguration configuration)
        {
            // Core infrastructure services
            services.AddHttpContextAccessor();
            services.AddScoped<eRents.Shared.Services.ICurrentUserService, eRents.WebApi.Shared.CurrentUserService>();
            services.AddSingleton<HttpClient>();
            
            // Message queue services
            services.AddSingleton<IRabbitMQService, RabbitMQService>();
            
            // Payment services with refactored architecture (Phase 1 refactoring)
            services.AddScoped<IPayPalGateway, PayPalService>();
            services.AddScoped<IPaymentService, PaymentService>();
            
            return services;
        }
    }
} 