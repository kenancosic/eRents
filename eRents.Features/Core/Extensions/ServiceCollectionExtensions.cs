using eRents.Features.Core.Filters;
using FluentValidation;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.DependencyInjection;
using System.Reflection;

namespace eRents.Features.Core.Extensions
{
    public static class ServiceCollectionExtensions
    {
        /// <summary>
        /// Adds validation services to the specified IServiceCollection
        /// </summary>
        /// <param name="services">The IServiceCollection to add services to</param>
        /// <param name="assemblies">Assemblies to scan for validators</param>
        /// <returns>The IServiceCollection so that additional calls can be chained</returns>
        public static IServiceCollection AddCustomValidation(
            this IServiceCollection services,
            params Assembly[] assemblies)
        {
            // Register FluentValidation with MVC
            services.AddFluentValidationAutoValidation(config =>
            {
                config.DisableDataAnnotationsValidation = true;
            });

            // Register validators from the specified assemblies
            services.AddValidatorsFromAssemblies(assemblies, includeInternalTypes: true);

            // Register our validation filter
            services.AddScoped<ValidationFilter>();

            // Configure MVC to use our validation filter
            services.Configure<MvcOptions>(options =>
            {
                options.Filters.Add<ValidationFilter>();
            });

            return services;
        }
    }
}
