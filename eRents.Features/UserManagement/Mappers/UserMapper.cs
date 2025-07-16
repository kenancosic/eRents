using eRents.Domain.Models;
using eRents.Features.UserManagement.DTOs;
using System.Security.Cryptography;
using System.Text;

namespace eRents.Features.UserManagement.Mappers;

/// <summary>
/// Mapper for converting between User entity and DTOs
/// Aligned with actual domain model and corrected DTOs
/// </summary>
public static class UserMapper
{
    /// <summary>
    /// Convert User entity to UserResponse DTO
    /// </summary>
    public static UserResponse ToUserResponse(this User entity)
    {
        return new UserResponse
        {
            Id = entity.UserId,                           // For compatibility
            UserId = entity.UserId,
            Username = entity.Username ?? string.Empty,
            Email = entity.Email ?? string.Empty,
            FirstName = entity.FirstName,                 // Nullable in corrected DTO
            LastName = entity.LastName,                   // Nullable in corrected DTO
            ProfileImageId = entity.ProfileImageId,
            UserTypeId = entity.UserTypeId,
            PhoneNumber = entity.PhoneNumber,             // Matches domain model exactly
            IsPaypalLinked = entity.IsPaypalLinked,
            PaypalUserIdentifier = entity.PaypalUserIdentifier,
            CreatedAt = entity.CreatedAt,
            UpdatedAt = entity.UpdatedAt,
            IsPublic = entity.IsPublic,                   // Nullable in corrected DTO
            DateOfBirth = entity.DateOfBirth?.ToDateTime(TimeOnly.MinValue), // Convert DateOnly? to DateTime?
            
            // Address value object properties (flattened for API response)
            StreetLine1 = entity.Address?.StreetLine1,
            StreetLine2 = entity.Address?.StreetLine2,
            City = entity.Address?.City,
            State = entity.Address?.State,
            Country = entity.Address?.Country,
            PostalCode = entity.Address?.PostalCode,
            Latitude = entity.Address?.Latitude,
            Longitude = entity.Address?.Longitude,
            
            // Navigation properties (populated separately if needed)
            UserTypeName = entity.UserTypeNavigation?.TypeName
        };
    }

    /// <summary>
    /// Convert UserRequest DTO to User entity for creation
    /// </summary>
    public static User ToEntity(this UserRequest request)
    {
        var (passwordHash, passwordSalt) = HashPassword(request.Password);
        
        return new User
        {
            Username = request.Username,
            Email = request.Email,
            FirstName = request.FirstName,
            LastName = request.LastName,
            PhoneNumber = request.PhoneNumber,
            UserTypeId = request.UserTypeId,
            IsPublic = request.IsPublic,
            DateOfBirth = request.DateOfBirth?.ToDateOnly(), // Convert DateTime? to DateOnly?
            
            // Password security
            PasswordHash = passwordHash,
            PasswordSalt = passwordSalt,
            
            // Create Address value object from individual fields
            Address = Address.Create(
                request.StreetLine1,
                request.StreetLine2,
                request.City,
                request.State,
                request.Country,
                request.PostalCode,
                request.Latitude,
                request.Longitude
            ),
            
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };
    }

    /// <summary>
    /// Convert UserInsertRequest DTO to User entity for registration
    /// </summary>
    public static User ToEntity(this UserInsertRequest request)
    {
        var (passwordHash, passwordSalt) = HashPassword(request.Password);
        
        return new User
        {
            Username = request.Username,
            Email = request.Email,
            FirstName = request.FirstName,
            LastName = request.LastName,
            PhoneNumber = request.PhoneNumber,
            UserTypeId = request.UserTypeId,
            
            // Password security
            PasswordHash = passwordHash,
            PasswordSalt = passwordSalt,
            
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };
    }

    /// <summary>
    /// Update existing User entity with UserUpdateRequest DTO data
    /// </summary>
    public static void UpdateEntity(this UserUpdateRequest request, User entity)
    {
        if (!string.IsNullOrEmpty(request.Username))
            entity.Username = request.Username;
            
        if (!string.IsNullOrEmpty(request.Email))
            entity.Email = request.Email;
            
        if (request.FirstName != null)
            entity.FirstName = request.FirstName;
            
        if (request.LastName != null)
            entity.LastName = request.LastName;
            
        if (request.PhoneNumber != null)
            entity.PhoneNumber = request.PhoneNumber;
            
        if (request.UserTypeId.HasValue)
            entity.UserTypeId = request.UserTypeId;
            
        if (request.IsPublic.HasValue)
            entity.IsPublic = request.IsPublic;
            
        if (request.IsPaypalLinked.HasValue)
            entity.IsPaypalLinked = request.IsPaypalLinked.Value;
            
        if (request.PaypalUserIdentifier != null)
            entity.PaypalUserIdentifier = request.PaypalUserIdentifier;
            
        if (request.DateOfBirth.HasValue)
            entity.DateOfBirth = request.DateOfBirth.Value.ToDateOnly();
        
        // Update Address if any address fields are provided
        if (request.StreetLine1 != null || request.City != null || request.Country != null ||
            request.StreetLine2 != null || request.State != null || request.PostalCode != null ||
            request.Latitude.HasValue || request.Longitude.HasValue)
        {
            var existingAddress = entity.Address;
            entity.Address = Address.Create(
                request.StreetLine1 ?? existingAddress?.StreetLine1,
                request.StreetLine2 ?? existingAddress?.StreetLine2,
                request.City ?? existingAddress?.City,
                request.State ?? existingAddress?.State,
                request.Country ?? existingAddress?.Country,
                request.PostalCode ?? existingAddress?.PostalCode,
                request.Latitude ?? existingAddress?.Latitude,
                request.Longitude ?? existingAddress?.Longitude
            );
        }
        
        entity.UpdatedAt = DateTime.UtcNow;
    }

    /// <summary>
    /// Hash password using PBKDF2 with random salt
    /// </summary>
    private static (byte[] hash, byte[] salt) HashPassword(string password)
    {
        var salt = new byte[32];
        using (var rng = RandomNumberGenerator.Create())
        {
            rng.GetBytes(salt);
        }
        
        using (var pbkdf2 = new Rfc2898DeriveBytes(password, salt, 10000, HashAlgorithmName.SHA256))
        {
            var hash = pbkdf2.GetBytes(32);
            return (hash, salt);
        }
    }

    /// <summary>
    /// Verify password against stored hash and salt
    /// </summary>
    public static bool VerifyPassword(string password, byte[] storedHash, byte[] storedSalt)
    {
        using (var pbkdf2 = new Rfc2898DeriveBytes(password, storedSalt, 10000, HashAlgorithmName.SHA256))
        {
            var hash = pbkdf2.GetBytes(32);
            return hash.SequenceEqual(storedHash);
        }
    }

    /// <summary>
    /// Convert list of User entities to UserResponse DTOs
    /// </summary>
    public static List<UserResponse> ToResponseList(this IEnumerable<User> users)
    {
        return users.Select(u => u.ToUserResponse()).ToList();
    }
}

/// <summary>
/// Extension methods for date conversions
/// </summary>
public static class DateTimeExtensions
{
    public static DateOnly ToDateOnly(this DateTime dateTime)
    {
        return DateOnly.FromDateTime(dateTime);
    }
} 