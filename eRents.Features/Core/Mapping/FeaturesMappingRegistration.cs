using Mapster;
using Microsoft.Extensions.DependencyInjection;

namespace eRents.Features.Core.Mapping
{
    /// <summary>
    /// Centralized registration point for per-feature Mapster mapping configurations within the Features assembly.
    /// This extension method aggregates feature-level Configure(TypeAdapterConfig) calls so each feature can register
    /// its mappings in a single, cohesive place.
    ///
    /// Coexistence/rollback: This setup is additive and transport-agnostic. It does not modify or replace existing
    /// services or AutoMapper usage. If needed, it can be rolled back by removing this extension invocation without
    /// impacting other mapping infrastructure.
    /// </summary>
    public static class FeaturesMappingRegistration
    {
        /// <summary>
        /// Registers Mapster configurations from individual feature mapping modules.
        /// This method intentionally contains commented placeholders for future feature registrations as the codebase evolves.
        /// </summary>
        /// <param name="services">The service collection to extend.</param>
        /// <param name="config">The Mapster TypeAdapter configuration to be augmented by feature mappings.</param>
        /// <returns>The same IServiceCollection instance for chaining.</returns>
        public static IServiceCollection AddFeaturesMappings(this IServiceCollection services, TypeAdapterConfig config)
        {
            // Ensure config is not null to avoid runtime misconfiguration
            if (config is null) throw new ArgumentNullException(nameof(config));
        
            // Register Property Management mappings
            PropertyManagement.Mapping.PropertyMapping.Configure(config);
        
            // Register Booking Management mappings
            BookingManagement.Mapping.BookingMapping.Configure(config);
        
            // Register Image Management mappings
            ImageManagement.Mapping.ImageMapping.Configure(config);
        
            // Register Review Management mappings
            ReviewManagement.Mapping.ReviewMapping.Configure(config);
        
            // Register Tenant Management mappings
            TenantManagement.Mapping.TenantMapping.Configure(config);
        
            // Register Payment Management mappings
            PaymentManagement.Mapping.PaymentMapping.Configure(config);
            
            // Register User Management mappings
            UserManagement.Mapping.UserMapping.Configure(config);
        
            return services;
        }
    }
}