using eRents.Features.Shared.DTOs;
using System.ComponentModel.DataAnnotations;

namespace eRents.Features.UserManagement.DTOs;

/// <summary>
/// User response DTO - aligned with actual User domain model
/// </summary>
public class UserResponse
{
    public int Id { get; set; }                       // For compatibility
    public int UserId { get; set; }
    public string Username { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string? FirstName { get; set; }            // Nullable in domain model
    public string? LastName { get; set; }             // Nullable in domain model
    public int? ProfileImageId { get; set; }
    public int? UserTypeId { get; set; }
    public string? PhoneNumber { get; set; }          // Matches domain model exactly
    public bool IsPaypalLinked { get; set; }
    public string? PaypalUserIdentifier { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
    public bool? IsPublic { get; set; }               // Nullable in domain model
    public DateTime? DateOfBirth { get; set; }        // Maps from DateOnly? - converted to DateTime for API
    
    // Address value object properties (flattened for API response)
    public string? StreetLine1 { get; set; }          // From Address.StreetLine1
    public string? StreetLine2 { get; set; }          // From Address.StreetLine2  
    public string? City { get; set; }                 // From Address.City
    public string? State { get; set; }                // From Address.State
    public string? Country { get; set; }              // From Address.Country
    public string? PostalCode { get; set; }           // From Address.PostalCode
    public decimal? Latitude { get; set; }            // From Address.Latitude
    public decimal? Longitude { get; set; }           // From Address.Longitude
    
    // Navigation properties (populated separately if needed)
    public string? UserTypeName { get; set; }         // From UserType.TypeName
    
    // Computed properties
    public string FullName => $"{FirstName} {LastName}".Trim();
    public string? FullAddress => $"{StreetLine1}, {City}, {Country}".Trim(' ', ',');
}

/// <summary>
/// User request for creating new users - aligned with domain model
/// </summary>
public class UserRequest
{
    [Required]
    [StringLength(100)]
    public string Username { get; set; } = string.Empty;
    
    [Required]
    [EmailAddress]
    [StringLength(255)]
    public string Email { get; set; } = string.Empty;
    
    [StringLength(100)]
    public string? FirstName { get; set; }            // Nullable to match domain model
    
    [StringLength(100)]
    public string? LastName { get; set; }             // Nullable to match domain model
    
    [Required]
    [StringLength(100, MinimumLength = 6)]
    public string Password { get; set; } = string.Empty;
    
    [StringLength(20)]
    public string? PhoneNumber { get; set; }          // Matches domain model exactly
    
    public int? UserTypeId { get; set; }
    public bool? IsPublic { get; set; }               // Nullable to match domain model
    public DateTime? DateOfBirth { get; set; }        // Will be converted to DateOnly
    
    // Address value object properties
    [StringLength(255)]
    public string? StreetLine1 { get; set; }
    
    [StringLength(255)]
    public string? StreetLine2 { get; set; }
    
    [StringLength(100)]
    public string? City { get; set; }
    
    [StringLength(100)]
    public string? State { get; set; }
    
    [StringLength(100)]
    public string? Country { get; set; }
    
    [StringLength(20)]
    public string? PostalCode { get; set; }
    
    [Range(-90, 90)]
    public decimal? Latitude { get; set; }
    
    [Range(-180, 180)]
    public decimal? Longitude { get; set; }
}

/// <summary>
/// User insert request (minimal fields for registration)
/// </summary>
public class UserInsertRequest
{
    [Required]
    [StringLength(100)]
    public string Username { get; set; } = string.Empty;
    
    [Required]
    [EmailAddress]
    [StringLength(255)]
    public string Email { get; set; } = string.Empty;
    
    [Required]
    [StringLength(100, MinimumLength = 6)]
    public string Password { get; set; } = string.Empty;
    
    [StringLength(100)]
    public string? FirstName { get; set; }
    
    [StringLength(100)]
    public string? LastName { get; set; }
    
    [StringLength(20)]
    public string? PhoneNumber { get; set; }
    
    public int? UserTypeId { get; set; }
}

/// <summary>
/// User update request - aligned with domain model
/// </summary>
public class UserUpdateRequest
{
    [StringLength(100)]
    public string? Username { get; set; }
    
    [EmailAddress]
    [StringLength(255)]
    public string? Email { get; set; }
    
    [StringLength(100)]
    public string? FirstName { get; set; }
    
    [StringLength(100)]
    public string? LastName { get; set; }
    
    [StringLength(20)]
    public string? PhoneNumber { get; set; }          // Matches domain model exactly
    
    public int? UserTypeId { get; set; }
    public bool? IsPublic { get; set; }               // Nullable to match domain model
    public bool? IsPaypalLinked { get; set; }
    public string? PaypalUserIdentifier { get; set; }
    public DateTime? DateOfBirth { get; set; }        // Will be converted to DateOnly
    
    // Address value object properties
    [StringLength(255)]
    public string? StreetLine1 { get; set; }
    
    [StringLength(255)]
    public string? StreetLine2 { get; set; }
    
    [StringLength(100)]
    public string? City { get; set; }
    
    [StringLength(100)]
    public string? State { get; set; }
    
    [StringLength(100)]
    public string? Country { get; set; }
    
    [StringLength(20)]
    public string? PostalCode { get; set; }
    
    [Range(-90, 90)]
    public decimal? Latitude { get; set; }
    
    [Range(-180, 180)]
    public decimal? Longitude { get; set; }
}

/// <summary>
/// Login request
/// </summary>
public class LoginRequest
{
    public string? Email { get; set; }
    public string? Username { get; set; }
    public string UsernameOrEmail { get; set; } = string.Empty;
    
    [Required]
    public string Password { get; set; } = string.Empty;
    
    public string? ClientType { get; set; }
}

/// <summary>
/// Login response
/// </summary>
public class LoginResponse
{
    public string Token { get; set; } = string.Empty;
    public DateTime Expiration { get; set; }
    public string? Platform { get; set; }
    public UserResponse User { get; set; } = new();
}

/// <summary>
/// Change password request
/// </summary>
public class ChangePasswordRequest
{
    [Required]
    public string CurrentPassword { get; set; } = string.Empty;
    
    [Required]
    [StringLength(100, MinimumLength = 6)]
    public string NewPassword { get; set; } = string.Empty;
}

/// <summary>
/// Reset password request
/// </summary>
public class ResetPasswordRequest
{
    [Required]
    [EmailAddress]
    public string Email { get; set; } = string.Empty;
    
    public string? ResetToken { get; set; }
    
    [StringLength(100, MinimumLength = 6)]
    public string? NewPassword { get; set; }
}

/// <summary>
/// Link PayPal request
/// </summary>
public class LinkPayPalRequest
{
    [Required]
    [EmailAddress]
    public string Email { get; set; } = string.Empty;
    
    [Required]
    [EmailAddress]
    public string PayPalEmail { get; set; } = string.Empty;
    
    public string? PayPalUserId { get; set; }
    public bool VerifyAccount { get; set; } = true;
}
