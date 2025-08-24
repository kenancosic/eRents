using Microsoft.Extensions.DependencyInjection;
using FluentValidation;
using eRents.Domain.Models;
using eRents.Features.Core;
using eRents.Features.ImageManagement.Models;
using eRents.Features.ImageManagement.Services;
using eRents.Features.ImageManagement.Validators;

namespace eRents.Features.ImageManagement.Extensions;

/// <summary>
/// Extension methods for registering ImageManagement services and validators.
/// </summary>
public static class ImageManagementServiceCollectionExtensions
{
    /// <summary>
    /// Registers ImageManagement feature services, CRUD mappings, and validators.
    /// </summary>
    public static IServiceCollection AddImageManagement(this IServiceCollection services)
    {
        // Concrete service
        services.AddScoped<ImageService>();

        // Generic CRUD mapping
        services.AddScoped<ICrudService<Image, ImageRequest, ImageResponse, ImageSearch>, ImageService>();

        // Validators
        services.AddScoped<IValidator<ImageRequest>, ImageRequestValidator>();

        return services;
    }
}
