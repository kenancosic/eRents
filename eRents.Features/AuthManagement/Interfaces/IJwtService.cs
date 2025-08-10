using eRents.Domain.Models;

namespace eRents.Features.AuthManagement.Interfaces;

/// <summary>
/// Interface for JWT token operations
/// </summary>
public interface IJwtService
{
    /// <summary>
    /// Generates JWT access token for authenticated user
    /// </summary>
    /// <param name="user">Authenticated user</param>
    /// <param name="clientSource">Client source (e.g., "desktop" or "mobile")</param>
    /// <returns>JWT token string</returns>
    string GenerateAccessToken(User user, string clientSource);

    /// <summary>
    /// Generates refresh token for token renewal
    /// </summary>
    /// <returns>Refresh token string</returns>
    string GenerateRefreshToken();

    /// <summary>
    /// Validates JWT token and extracts user claims
    /// </summary>
    /// <param name="token">JWT token to validate</param>
    /// <returns>User ID if valid, null otherwise</returns>
    int? ValidateToken(string token);

    /// <summary>
    /// Gets token expiration time
    /// </summary>
    /// <returns>Token expiration DateTime in UTC</returns>
    DateTime GetTokenExpiration();
}