using Microsoft.Extensions.DependencyInjection;
using FluentValidation;
using eRents.Domain.Models;
using eRents.Features.Core;
using eRents.Features.TenantManagement.Models;
using eRents.Features.TenantManagement.Services;
using eRents.Features.TenantManagement.Validators;

namespace eRents.Features.TenantManagement.Extensions;

/// <summary>
/// Extension methods for registering TenantManagement services and validators.
/// </summary>
public static class TenantManagementServiceCollectionExtensions
{
    /// <summary>
    /// Registers TenantManagement feature services, CRUD mappings, and validators.
    /// </summary>
    public static IServiceCollection AddTenantManagement(this IServiceCollection services)
    {
        // Concrete service
        services.AddScoped<TenantService>();

        // Generic CRUD mapping
        services.AddScoped<ICrudService<Tenant, TenantRequest, TenantResponse, TenantSearch>, TenantService>();

        // Validators
        services.AddScoped<IValidator<TenantRequest>, TenantRequestValidator>();

        return services;
    }
}
