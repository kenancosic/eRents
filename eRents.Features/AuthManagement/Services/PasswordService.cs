using System.Security.Cryptography;
using System.Text;
using eRents.Features.AuthManagement.Interfaces;

namespace eRents.Features.AuthManagement.Services;

/// <summary>
/// Service for password hashing and verification using PBKDF2 (academic settings)
///
/// IMPORTANT: Matches the AcademicDataSeeder parameters for consistency
///  - Algorithm: PBKDF2 with SHA-256
///  - Salt size: 16 bytes
///  - Hash size: 20 bytes
///  - Iterations: 10,000
/// </summary>
public sealed class PasswordService : IPasswordService
{
    // Academic-level parameters (kept simple and to match seeding)
    private const int SaltSize = 16; // 128 bits
    private const int HashSize = 20; // 160 bits
    private const int Iterations = 10000; 

    public byte[] HashPassword(string password, out byte[] salt)
    {
        if (string.IsNullOrEmpty(password))
            throw new ArgumentException("Password cannot be null or empty", nameof(password));

        // Generate random salt
        salt = new byte[SaltSize];
        using (var rng = RandomNumberGenerator.Create())
        {
            rng.GetBytes(salt);
        }

        // Hash password with salt using PBKDF2 (SHA-256)
        using (var pbkdf2 = new Rfc2898DeriveBytes(password, salt, Iterations, HashAlgorithmName.SHA256))
        {
            return pbkdf2.GetBytes(HashSize);
        }
    }

    public bool VerifyPassword(string password, byte[] hash, byte[] salt)
    {
        if (string.IsNullOrEmpty(password))
            return false;

        if (hash == null || salt == null)
            return false;

        if (hash.Length != HashSize || salt.Length != SaltSize)
            return false;

        try
        {
            // Hash the provided password with the stored salt
            using (var pbkdf2 = new Rfc2898DeriveBytes(password, salt, Iterations, HashAlgorithmName.SHA256))
            {
                byte[] computedHash = pbkdf2.GetBytes(HashSize);

                // Compare hashes in constant time to prevent timing attacks
                return CryptographicOperations.FixedTimeEquals(hash, computedHash);
            }
        }
        catch
        {
            return false;
        }
    }

    public string GenerateResetToken()
    {
        // Generate a cryptographically secure random token
        using (var rng = RandomNumberGenerator.Create())
        {
            byte[] tokenBytes = new byte[32]; // 256 bits
            rng.GetBytes(tokenBytes);
            
            // Convert to URL-safe base64 string
            return Convert.ToBase64String(tokenBytes)
                .Replace('+', '-')
                .Replace('/', '_')
                .TrimEnd('=');
        }
    }
}