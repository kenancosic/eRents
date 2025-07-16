using System.Security.Claims;

namespace eRents.Domain.Shared.Interfaces;

/// <summary>
/// Defines the interface for a service that provides information about the current authenticated user.
/// This interface is placed in the Domain.Shared project to be accessible by the Domain layer (e.g., ERentsContext)
/// without violating clean architecture principles.
/// </summary>
public interface ICurrentUserService
{
    string? UserId { get; }
    string? UserRole { get; }
    string? Email { get; }
    bool IsAuthenticated { get; }
    int? GetUserIdAsInt();
    IEnumerable<Claim> GetUserClaims();
}
