using eRents.Domain.Models.Enums;

namespace eRents.Features.AuthManagement.Models;

/// <summary>
/// Response model for successful authentication
/// </summary>
public sealed class AuthResponse
{
    /// <summary>
    /// JWT access token
    /// </summary>
    public string AccessToken { get; set; } = null!;

    /// <summary>
    /// JWT refresh token for token renewal
    /// </summary>
    public string RefreshToken { get; set; } = null!;

    /// <summary>
    /// Token expiration time in UTC
    /// </summary>
    public DateTime ExpiresAt { get; set; }

    /// <summary>
    /// Authenticated user information
    /// </summary>
    public UserInfo User { get; set; } = null!;
}

/// <summary>
/// Basic user information included in auth response
/// </summary>
public sealed class UserInfo
{
    public int UserId { get; set; }
    public string Username { get; set; } = null!;
    public string Email { get; set; } = null!;
    public string? FirstName { get; set; }
    public string? LastName { get; set; }
    public UserTypeEnum UserType { get; set; }
    public int? ProfileImageId { get; set; }
}