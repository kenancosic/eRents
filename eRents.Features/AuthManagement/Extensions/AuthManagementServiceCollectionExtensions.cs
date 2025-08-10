using Microsoft.Extensions.DependencyInjection;
using FluentValidation;
using eRents.Features.AuthManagement.Interfaces;
using eRents.Features.AuthManagement.Services;
using eRents.Features.AuthManagement.Models;
using eRents.Features.AuthManagement.Validators;

namespace eRents.Features.AuthManagement.Extensions;

/// <summary>
/// Extension methods for registering AuthManagement services
/// </summary>
public static class AuthManagementServiceCollectionExtensions
{
    /// <summary>
    /// Registers all AuthManagement services and dependencies
    /// </summary>
    public static IServiceCollection AddAuthManagement(this IServiceCollection services)
    {
        // Core authentication services
        services.AddScoped<IAuthService, AuthService>();
        services.AddScoped<IPasswordService, PasswordService>();
        services.AddScoped<IJwtService, JwtService>();

        // Validators
        services.AddScoped<IValidator<LoginRequest>, LoginRequestValidator>();
        services.AddScoped<IValidator<RegisterRequest>, RegisterRequestValidator>();
        services.AddScoped<IValidator<ForgotPasswordRequest>, ForgotPasswordRequestValidator>();
        services.AddScoped<IValidator<ResetPasswordRequest>, ResetPasswordRequestValidator>();

        return services;
    }
}