using eRents.Domain.Shared.Interfaces;
using eRents.Features.PaymentManagement.Services;
using eRents.Features.Shared.Services;
using eRents.Features.ImageManagement.Services;
using eRents.Features.PropertyManagement.Services;
using eRents.Features.PropertyManagement.Extensions;
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
using eRents.Features.Core.Interfaces;
using eRents.Features.Core.Services;
using eRents.WebApi.Services;
using Microsoft.AspNetCore.SignalR;
using eRents.WebApi.Hubs;
using eRents.WebApi.Data.Seeding;
using eRents.WebApi.Data.Seeding.Seeders;

namespace eRents.WebApi.Extensions;

public static class ServiceRegistrationExtensions
{
	public static void ConfigureServices(this IServiceCollection services, IConfiguration configuration)
	{
		// Host-level concerns like DbContext, AutoMapper, and validation are configured in Program.cs

		services.AddScoped<ICurrentUserService, CurrentUserService>();
		// Cross-cutting infrastructure for outbound HTTP and caching (used by Stripe integration)
		services.AddHttpClient();
		services.AddMemoryCache();

		// Stripe payment configuration
		services.Configure<eRents.Features.PaymentManagement.Services.StripeOptions>(configuration.GetSection("Stripe"));
		
		// Initialize Stripe globally
		var stripeOptions = configuration.GetSection("Stripe").Get<eRents.Features.PaymentManagement.Services.StripeOptions>();
		if (stripeOptions != null)
		{
			stripeOptions.Validate();
			Stripe.StripeConfiguration.ApiKey = stripeOptions.SecretKey;
		}
		
		services.AddScoped<eRents.Features.PaymentManagement.Interfaces.IStripePaymentService, eRents.Features.PaymentManagement.Services.StripePaymentService>();
		services.AddScoped<eRents.Features.PaymentManagement.Interfaces.IStripeConnectService, eRents.Features.PaymentManagement.Services.StripeConnectService>();

		// Feature registration happens below via extension methods block

		// Core/Shared services
		services.AddScoped<ImageService>();
		services.AddScoped<IOwnershipService, OwnershipService>();

		services.AddScoped<IMessagingService, MessagingService>();
		services.AddScoped<INotificationService, NotificationService>();
		services.AddScoped<eRents.Shared.Services.IEmailService, RabbitMqEmailPublisher>();
		services.AddScoped<ISubscriptionService, SubscriptionService>();
		services.AddScoped<IInvoicePdfService, InvoicePdfService>();

		// Bridge hub context so Features-layer MessagingService (expects IHubContext<Hub>)
		// can publish via the concrete ChatHub without referencing WebApi types.
		services.AddSingleton<IHubContext<Hub>>(sp => sp.GetRequiredService<IHubContext<ChatHub>>());

		// All feature services are now registered via extension methods

		// Register all feature services via extension methods
		services.AddBookingManagement();
		services.AddImageManagement();
		services.AddLookupManagement();
		services.AddMaintenanceManagement();
		services.AddPaymentManagement();
		services.AddPropertyManagement();
		services.AddReviewManagement();
		services.AddTenantManagement();

		// Note: UserService may expose a richer, non-generic interface; don't bind to ICrudService unless implemented

		// Register AuthManagement services
		services.AddAuthManagement();

		// Register UserManagement feature services explicitly
		services.AddUserManagement();

		        // Seeding registrations
			services.AddScoped<IDataSeeder, AmenitySeeder>();
			services.AddScoped<IDataSeeder, UsersSeeder>();
			services.AddScoped<IDataSeeder, UserProfileImagesSeeder>();
			services.AddScoped<IDataSeeder, PropertiesSeeder>();
			services.AddScoped<IDataSeeder, PropertyImagesSeeder>();
		services.AddScoped<IDataSeeder, MaintenanceImagesSeeder>();
			services.AddScoped<IDataSeeder, BookingsSeeder>();
			// Diversify booking statuses (Completed/Cancelled)
			services.AddScoped<IDataSeeder, BookingsVarietySeeder>();
			// Daily rental bookings with pending/approval scenarios
			services.AddScoped<IDataSeeder, DailyRentalBookingsSeeder>();
			services.AddScoped<IDataSeeder, SubscriptionsSeeder>();
			// Pending lease extension requests for demo
			services.AddScoped<IDataSeeder, LeaseExtensionRequestsSeeder>();
			services.AddScoped<IDataSeeder, ReviewsSeeder>();
			// Threaded replies and tenant reviews
			services.AddScoped<IDataSeeder, ReviewRepliesSeeder>();
			// Historical payments and refund linkage
			services.AddScoped<IDataSeeder, PaymentsSeeder>();
			// Failed payment scenarios for error handling testing
			services.AddScoped<IDataSeeder, FailedPaymentsSeeder>();
			services.AddScoped<IDataSeeder, MaintenanceIssuesSeeder>();
			// Enhanced maintenance issues with assignment/resolution and images
			services.AddScoped<IDataSeeder, MaintenanceEnhancementsSeeder>();
			services.AddScoped<IDataSeeder, SavedPropertiesSeeder>();
			services.AddScoped<IDataSeeder, MessagesSeeder>();
			services.AddScoped<IDataSeeder, NotificationsSeeder>();
			services.AddScoped<DataSeeder>();

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