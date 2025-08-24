using Microsoft.Extensions.DependencyInjection;
using FluentValidation;
using eRents.Domain.Models;
using eRents.Features.Core;
using eRents.Features.ReviewManagement.Models;
using eRents.Features.ReviewManagement.Services;
using eRents.Features.ReviewManagement.Validators;

namespace eRents.Features.ReviewManagement.Extensions;

/// <summary>
/// Extension methods for registering ReviewManagement services and validators.
/// </summary>
public static class ReviewManagementServiceCollectionExtensions
{
    /// <summary>
    /// Registers ReviewManagement feature services, CRUD mappings, and validators.
    /// </summary>
    public static IServiceCollection AddReviewManagement(this IServiceCollection services)
    {
        // Concrete service
        services.AddScoped<ReviewService>();

        // Generic CRUD mapping
        services.AddScoped<ICrudService<Review, ReviewRequest, ReviewResponse, ReviewSearch>, ReviewService>();

        // Validators
        services.AddScoped<IValidator<ReviewRequest>, ReviewRequestValidator>();

        return services;
    }
}
