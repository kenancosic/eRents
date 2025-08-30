using FluentValidation;
using Microsoft.Extensions.DependencyInjection;
using eRents.Domain.Models;
using eRents.Features.Core;
using eRents.Features.MaintenanceManagement.Models;
using eRents.Features.MaintenanceManagement.Services;
using eRents.Features.MaintenanceManagement.Validators;

namespace eRents.Features.MaintenanceManagement.Extensions;

/// <summary>
/// Extension methods for registering MaintenanceManagement services.
/// </summary>
public static class MaintenanceManagementServiceCollectionExtensions
{
    /// <summary>
    /// Registers MaintenanceManagement feature services and CRUD mappings.
    /// </summary>
    public static IServiceCollection AddMaintenanceManagement(this IServiceCollection services)
    {
        // Concrete service
        services.AddScoped<MaintenanceIssueService>();

        // Generic CRUD mapping
        services.AddScoped<ICrudService<MaintenanceIssue, MaintenanceIssueRequest, MaintenanceIssueResponse, MaintenanceIssueSearch>, MaintenanceIssueService>();

        // FluentValidation
        services.AddScoped<IValidator<MaintenanceIssueRequest>, MaintenanceIssueRequestValidator>();

        return services;
    }
}
