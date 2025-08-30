using eRents.Domain.Shared.Interfaces;
using eRents.Features.PaymentManagement.Services;
using eRents.Features.Shared.Services;
using eRents.Features.ImageManagement.Services;
using eRents.Features.PropertyManagement.Services;
using eRents.Features.AuthManagement.Extensions;
using eRents.Features.UserManagement.Extensions;
using eRents.Features.BookingManagement.Extensions;
using eRents.Features.ImageManagement.Extensions;
using eRents.Features.LookupManagement.Extensions;
using eRents.Features.MaintenanceManagement.Extensions;
using eRents.Features.PaymentManagement.Extensions;
using eRents.Features.ReviewManagement.Extensions;
using eRents.Features.TenantManagement.Extensions;
using eRents.Features.Core;
using eRents.WebApi.Services;

namespace eRents.WebApi.Extensions;

public static class ServiceRegistrationExtensions
{
	public static void ConfigureServices(this IServiceCollection services, IConfiguration configuration)
	{
		// Host-level concerns like DbContext, AutoMapper, and validation are configured in Program.cs

		services.AddScoped<ICurrentUserService, CurrentUserService>();
		// Cross-cutting infrastructure for outbound HTTP and caching (used by PayPal integration)
		services.AddHttpClient();
		services.AddMemoryCache();

		// PayPal sandbox/live configuration (Features namespace)
		services.Configure<PayPalOptions>(configuration.GetSection("PayPal"));
		services.AddSingleton<PayPalIdentityService>();

		// Feature registration happens below via extension methods block

		// Core/Shared services
		services.AddScoped<ImageService>();
		services.AddScoped<IMessagingService, MessagingService>();
		services.AddScoped<INotificationService, NotificationService>();
		services.AddScoped<eRents.Shared.Services.IEmailService, RabbitMqEmailPublisher>();

		// All feature services are now registered via extension methods

		// Register all feature services via extension methods
		services.AddBookingManagement();
		services.AddImageManagement();
		services.AddLookupManagement();
		services.AddMaintenanceManagement();
		services.AddPaymentManagement();
		services.AddReviewManagement();
		services.AddTenantManagement();

		// Note: UserService may expose a richer, non-generic interface; don't bind to ICrudService unless implemented

		// Register AuthManagement services
		services.AddAuthManagement();

		// Register UserManagement feature services explicitly
		services.AddUserManagement();

		// Auto-register all concrete services in eRents.Features that implement ICrudService<,,,>
		// This removes the need to manually add mappings for each feature service
		var featuresAssembly = typeof(PropertyService).Assembly; // eRents.Features
		var serviceTypes = featuresAssembly
				.GetTypes()
				.Where(t => !t.IsAbstract && !t.IsInterface);

		foreach (var impl in serviceTypes)
		{
			var crudInterfaces = impl
					.GetInterfaces()
					.Where(i => i.IsGenericType && i.GetGenericTypeDefinition() == typeof(ICrudService<,,,>));

			foreach (var crudIface in crudInterfaces)
			{
				services.AddScoped(crudIface, impl);
			}
		}

		// Additionally, auto-register any concrete *Service implementations with their feature interfaces
		// This covers non-CRUD services so frontend calls don't break when new services are added
		var featureServiceTypes = serviceTypes
				.Where(t => t.Name.EndsWith("Service", StringComparison.Ordinal));

		foreach (var impl in featureServiceTypes)
		{
			var interfaces = impl
					.GetInterfaces()
					// exclude the generic CRUD interface already handled above
					.Where(i => !(i.IsGenericType && i.GetGenericTypeDefinition() == typeof(ICrudService<,,,>)))
					// prefer feature interfaces only
					.Where(i => (i.Namespace ?? string.Empty).StartsWith("eRents.Features", StringComparison.Ordinal));

			foreach (var iface in interfaces)
			{
				// avoid duplicate registrations of same mapping
				var alreadyRegistered = services.Any(d => d.ServiceType == iface && d.ImplementationType == impl);
				if (!alreadyRegistered)
				{
					services.AddScoped(iface, impl);
				}
			}
		}
	}
}