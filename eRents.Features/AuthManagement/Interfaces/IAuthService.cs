using eRents.Features.AuthManagement.Models;

namespace eRents.Features.AuthManagement.Interfaces;

/// <summary>
/// Interface for authentication operations
/// </summary>
public interface IAuthService
{
    /// <summary>
    /// Authenticates user with username/email and password
    /// </summary>
    Task<AuthResponse?> LoginAsync(LoginRequest request);

    /// <summary>
    /// Registers a new user account
    /// </summary>
    Task<AuthResponse> RegisterAsync(RegisterRequest request);

    /// <summary>
    /// Initiates password reset process by generating reset token
    /// </summary>
    Task<bool> ForgotPasswordAsync(ForgotPasswordRequest request);

    /// <summary>
    /// Resets password using reset token
    /// </summary>
    Task<bool> ResetPasswordAsync(ResetPasswordRequest request);

    /// <summary>
    /// Verifies whether the provided reset code for the given email is valid and not expired.
    /// Used for password reset flow.
    /// </summary>
    Task<bool> VerifyResetCodeAsync(string email, string code);

    /// <summary>
    /// Verifies email address after signup and returns auth tokens for automatic login.
    /// Marks the user's email as verified.
    /// </summary>
    Task<AuthResponse?> VerifyEmailAsync(string email, string code);

    /// <summary>
    /// Refreshes JWT token using refresh token
    /// </summary>
    Task<AuthResponse?> RefreshTokenAsync(string refreshToken);

    /// <summary>
    /// Validates if username is available for registration
    /// </summary>
    Task<bool> IsUsernameAvailableAsync(string username);

    /// <summary>
    /// Validates if email is available for registration
    /// </summary>
    Task<bool> IsEmailAvailableAsync(string email);
}