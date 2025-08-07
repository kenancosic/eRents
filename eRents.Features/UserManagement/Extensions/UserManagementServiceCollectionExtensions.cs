using Mapster;
using Microsoft.Extensions.DependencyInjection;
using eRents.Domain.Models;
using eRents.Features.Core.Interfaces;
using eRents.Features.UserManagement.Mapping;
using eRents.Features.UserManagement.Models;
using eRents.Features.UserManagement.Services;

namespace eRents.Features.UserManagement.Extensions;

public static class UserManagementServiceCollectionExtensions
{
    /// <summary>
    /// Registers UserManagement feature services and mappings.
    /// Call this from composition root if using per-feature registration,
    /// otherwise rely on central registration points already present in the solution.
    /// </summary>
    public static IServiceCollection AddUserManagement(this IServiceCollection services, TypeAdapterConfig mapsterConfig)
    {
        // Service registration for generic CRUD
        services.AddScoped<ICrudService<User, UserRequest, UserResponse, UserSearch>, UserService>();

        // Mapster mapping config
        UserMapping.Configure(mapsterConfig);

        return services;
    }
}