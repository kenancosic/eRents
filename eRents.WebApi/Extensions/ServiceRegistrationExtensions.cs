using eRents.Domain.Shared;
using Microsoft.EntityFrameworkCore;
using eRents.Domain.Models;
using eRents.Domain.Shared.Interfaces;
using eRents.WebApi.Services;
using eRents.Features.Shared.Services;

using eRents.RabbitMQMicroservice.Services;
using eRents.Features.Core.Validation;
using eRents.Features.Core.Extensions;
using eRents.Features.ImageManagement.Services;
using eRents.Features.PropertyManagement.Models;
using eRents.Features.UserManagement.Services;
using eRents.Features.UserManagement.Models;
using eRents.Features.ReviewManagement.Models;
using eRents.Features.ReviewManagement.Services;
using eRents.Features.Core.Interfaces;
using eRents.Features.BookingManagement.Models;
using eRents.Features.BookingManagement.Services;
using eRents.Features.PaymentManagement.Services;
using eRents.Features.PaymentManagement.Models;
using eRents.Features.PropertyManagement.Services;
using eRents.Features.Core.Mapping;
using eRents.Features.LookupManagement.Interfaces;
using eRents.Features.LookupManagement.Services;

namespace eRents.WebApi.Extensions;

public static class ServiceRegistrationExtensions
{
	public static void ConfigureServices(this IServiceCollection services, IConfiguration configuration)
	{
		// Database Configuration
		services.AddDbContext<ERentsContext>(options =>
				options.UseSqlServer(configuration.GetConnectionString("DefaultConnection")));

		// AutoMapper - register all profiles from Features and WebApi assemblies
		// This provides AutoMapper.IMapper needed by feature services
		services.AddAutoMapper(
			typeof(ServiceRegistrationExtensions).Assembly,
			typeof(FeaturesMappingRegistration).Assembly
		);

		services.AddScoped<ICurrentUserService, CurrentUserService>();

		// Register CRUD abstractions and validation
		services.AddCustomValidation(
				typeof(ServiceRegistrationExtensions).Assembly,
				typeof(BaseValidator<>).Assembly
		);


		services.AddScoped<ImageService>();
		services.AddScoped<IMessagingService, MessagingService>();
		services.AddScoped<INotificationService, NotificationService>();
		services.AddScoped<IEmailService, SmtpEmailService>();

		services.AddScoped<DbContext, ERentsContext>();

		// Feature-Specific Services
		RegisterPropertyManagementServices(services);
		RegisterFinancialManagementServices(services);
		RegisterRentalManagementServices(services);
		RegisterReviewManagementServices(services);
		RegisterLookupManagementServices(services);

		RegisterUserManagementServices(services);
	}

	private static void RegisterLookupManagementServices(IServiceCollection services)
	{
		services.AddScoped<ILookupService, LookupService>();
		services.AddScoped<IAmenityService, AmenityService>();
		// Add other LookupManagement services and validators
	}

	private static void RegisterPropertyManagementServices(IServiceCollection services)
	{
		// Register concrete service only to avoid missing interface type errors
		services.AddScoped<PropertyService>();

		// Register generic interfaces for CrudController-based controllers
		services.AddScoped<
			ICrudService<Property, PropertyRequest, PropertyResponse, PropertySearch>,
			PropertyService
		>();

		services.AddScoped<IReadService<Property, PropertyResponse, PropertySearch>, PropertyService>();
	}


	private static void RegisterFinancialManagementServices(IServiceCollection services)
	{
		// Register concrete PaymentService
		services.AddScoped<PaymentService>();

		// Register generic interfaces for Payment CRUD endpoints if used
		services.AddScoped<ICrudService<Payment, PaymentRequest, PaymentResponse, PaymentSearch>, PaymentService>();

		services.AddScoped<
			IReadService<Payment, PaymentResponse, PaymentSearch>, PaymentService>();
	}


	private static void RegisterRentalManagementServices(IServiceCollection services)
	{
		// Register concrete RentalService if exists; otherwise leave empty
		// services.AddScoped<eRents.Features.RentalManagement.Services.RentalService>();
		// If/when BookingManagement is active under new pattern, bind generics here.
		services.AddScoped<ICrudService<Booking, BookingRequest, BookingResponse, BookingSearch>, BookingService>();

		services.AddScoped<IReadService<Booking, BookingResponse, BookingSearch>, BookingService>();
	}


	private static void RegisterReviewManagementServices(IServiceCollection services)
	{
		// Register concrete ReviewService
		services.AddScoped<ReviewService>();

		// Register generic interfaces for Review CRUD endpoints if used
		services.AddScoped<
			ICrudService<Review, ReviewRequest, ReviewResponse, ReviewSearch>, ReviewService>();

		services.AddScoped<IReadService<Review, ReviewResponse, ReviewSearch>, ReviewService>();
	}

	// User Management registration encapsulation
	private static void RegisterUserManagementServices(IServiceCollection services)
	{
		// Bind generic CRUD for User feature
		services.AddScoped<ICrudService<User, UserRequest, UserResponse, UserSearch>, UserService>();

		// Optionally expose IReadService separately if required by controllers (PublicUsersController uses IReadService)
		services.AddScoped<IReadService<User, UserResponse, UserSearch>, UserService>();
	}
}