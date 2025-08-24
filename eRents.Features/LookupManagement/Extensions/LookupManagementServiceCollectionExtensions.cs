using Microsoft.Extensions.DependencyInjection;
using FluentValidation;
using eRents.Domain.Models;
using eRents.Features.Core;
using eRents.Features.LookupManagement.Models;
using eRents.Features.LookupManagement.Services;
using eRents.Features.LookupManagement.Validators;
using eRents.Features.LookupManagement.Interfaces;

namespace eRents.Features.LookupManagement.Extensions;

/// <summary>
/// Extension methods for registering LookupManagement services and validators.
/// </summary>
public static class LookupManagementServiceCollectionExtensions
{
    /// <summary>
    /// Registers LookupManagement feature services, CRUD mappings, and validators.
    /// </summary>
    public static IServiceCollection AddLookupManagement(this IServiceCollection services)
    {
        // Concrete services
        services.AddScoped<LookupService>();
        services.AddScoped<AmenityService>();

        // Interface mappings
        services.AddScoped<ILookupService, LookupService>();
        services.AddScoped<IAmenityService, AmenityService>();

        // Generic CRUD mapping for Amenity
        services.AddScoped<ICrudService<Amenity, AmenityRequest, AmenityResponse, AmenitySearchObject>, AmenityService>();

        // Validators
        services.AddScoped<IValidator<AmenityRequest>, AmenityRequestValidator>();

        return services;
    }
}
