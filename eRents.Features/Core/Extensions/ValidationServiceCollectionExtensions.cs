using eRents.Features.Core.Filters;
using FluentValidation;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using System.Reflection;
using eRents.Features.PropertyManagement.Services;
using eRents.Features.TenantManagement.Services;

namespace eRents.Features.Core.Extensions
{
	// Renamed for clarity to avoid confusion with other extension classes
	public static class ValidationServiceCollectionExtensions
	{
		/// <summary>
		/// Adds validation services to the specified IServiceCollection without FluentValidation.AspNetCore.
		/// - Disables DataAnnotations validation
		/// - Registers all IValidator<> from provided assemblies
		/// - Adds a global ValidationFilter to run validators
		/// </summary>
		/// <param name="services">The IServiceCollection to add services to</param>
		/// <param name="assemblies">Assemblies to scan for validators</param>
		/// <returns>The IServiceCollection so that additional calls can be chained</returns>
		public static IServiceCollection AddCustomValidation(
				this IServiceCollection services,
				params Assembly[] assemblies)
		{
			// Register feature services (Property) - register concrete type (interfaces do not exist)
			services.AddScoped<PropertyService>();
			// Disable DataAnnotations (keep single source of validation: FluentValidation)
			services.Configure<MvcOptions>(options =>
			{
				options.ModelValidatorProviders.Clear();
			});

			// Register validators from the specified assemblies (manual scan, no deprecated package)
			if (assemblies is { Length: > 0 })
			{
				foreach (var assembly in assemblies)
				{
					RegisterValidatorsFromAssembly(services, assembly);
				}
			}

			// Register feature services (Property, Tenant) - register concrete types
			services.AddScoped<PropertyService>();
			services.AddScoped<TenantService>();

			// Register our validation filter
			services.TryAddScoped<ValidationFilter>();

			// Configure MVC to use our validation filter globally
			services.Configure<MvcOptions>(options =>
			{
				options.Filters.Add<ValidationFilter>();
			});

			return services;
		}

		private static void RegisterValidatorsFromAssembly(IServiceCollection services, Assembly assembly)
		{
			// Find all validator types implementing IValidator<T>
			var validatorTypes = assembly
				.GetTypes()
				.Where(t => !t.IsAbstract && !t.IsInterface)
				.SelectMany(t => t.GetInterfaces()
					.Where(i => i.IsGenericType && i.GetGenericTypeDefinition() == typeof(IValidator<>))
					.Select(i => new { ServiceType = i, ImplementationType = t }))
				.ToList();

			foreach (var reg in validatorTypes)
			{
				services.TryAddScoped(reg.ServiceType, reg.ImplementationType);
			}
		}
	}
}
