using Microsoft.Extensions.DependencyInjection;

namespace eRents.Features.Core.Mapping
{
    /// <summary>
    /// Legacy Mapster registration placeholder. No-op to decouple from Mapster.
    /// Safe to remove once all callers are deleted.
    /// </summary>
    public static class FeaturesMappingRegistration
    {
        /// <summary>
        /// No-op. Retained only to avoid breaking any leftover calls during migration.
        /// </summary>
        public static IServiceCollection AddFeaturesMappings(this IServiceCollection services)
        {
            return services;
        }
    }
}