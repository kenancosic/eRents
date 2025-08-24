using Microsoft.Extensions.DependencyInjection;
using FluentValidation;
using eRents.Domain.Models;
using eRents.Features.Core;
using eRents.Features.PropertyManagement.Models;
using eRents.Features.PropertyManagement.Services;
using eRents.Features.PropertyManagement.Validators;

namespace eRents.Features.PropertyManagement.Extensions;

/// <summary>
/// Extension methods for registering PropertyManagement services and validators.
/// </summary>
public static class PropertyManagementServiceCollectionExtensions
{
    /// <summary>
    /// Registers PropertyManagement feature services, CRUD mappings, and validators.
    /// </summary>
    public static IServiceCollection AddPropertyManagement(this IServiceCollection services)
    {
        // Concrete service
        services.AddScoped<PropertyService>();

        // Generic CRUD mapping
        services.AddScoped<ICrudService<Property, PropertyRequest, PropertyResponse, PropertySearch>, PropertyService>();

        // Validators
        services.AddScoped<IValidator<PropertyRequest>, PropertyRequestValidator>();

        return services;
    }
}
