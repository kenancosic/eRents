using Microsoft.Extensions.DependencyInjection;
using eRents.Domain.Models;
using eRents.Features.UserManagement.Models;
using eRents.Features.UserManagement.Services;
using eRents.Features.Core;

namespace eRents.Features.UserManagement.Extensions;

public static class UserManagementServiceCollectionExtensions
{
    /// <summary>
    /// Registers UserManagement feature services.
    /// Call this from composition root if using per-feature registration,
    /// otherwise rely on central registration points already present in the solution.
    /// </summary>
    public static IServiceCollection AddUserManagement(this IServiceCollection services)
    {
        // Service registration for generic CRUD
        services.AddScoped<ICrudService<User, UserRequest, UserResponse, UserSearch>, UserService>();

        return services;
    }
}