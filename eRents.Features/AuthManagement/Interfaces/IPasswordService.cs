namespace eRents.Features.AuthManagement.Interfaces;

/// <summary>
/// Interface for password hashing and verification operations
/// </summary>
public interface IPasswordService
{
    /// <summary>
    /// Hashes a plain text password with salt
    /// </summary>
    /// <param name="password">Plain text password</param>
    /// <param name="salt">Generated salt</param>
    /// <returns>Password hash</returns>
    byte[] HashPassword(string password, out byte[] salt);

    /// <summary>
    /// Verifies a password against stored hash and salt
    /// </summary>
    /// <param name="password">Plain text password to verify</param>
    /// <param name="hash">Stored password hash</param>
    /// <param name="salt">Stored salt</param>
    /// <returns>True if password matches</returns>
    bool VerifyPassword(string password, byte[] hash, byte[] salt);

    /// <summary>
    /// Generates a secure random token for password reset
    /// </summary>
    /// <returns>Random token string</returns>
    string GenerateResetToken();
}