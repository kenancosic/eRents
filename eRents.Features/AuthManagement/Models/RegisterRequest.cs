using System.ComponentModel.DataAnnotations;
using eRents.Domain.Models.Enums;

namespace eRents.Features.AuthManagement.Models;

/// <summary>
/// Request model for user registration
/// </summary>
public sealed class RegisterRequest
{
    [Required]
    [StringLength(50, MinimumLength = 3)]
    public string Username { get; set; } = null!;

    [Required]
    [EmailAddress]
    [StringLength(100)]
    public string Email { get; set; } = null!;

    [Required]
    [StringLength(100, MinimumLength = 8)]
    [RegularExpression(@"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]", 
        ErrorMessage = "Password must contain at least one lowercase letter, one uppercase letter, one digit, and one special character.")]
    public string Password { get; set; } = null!;

    [Required]
    [Compare("Password")]
    public string ConfirmPassword { get; set; } = null!;

    [StringLength(100)]
    public string? FirstName { get; set; }

    [StringLength(100)]
    public string? LastName { get; set; }

    [Phone]
    [StringLength(20)]
    public string? PhoneNumber { get; set; }

    /// <summary>
    /// Address - required fields for registration
    /// </summary>
    [Required]
    [StringLength(100)]
    public string City { get; set; } = null!;

    [Required]
    [StringLength(20)]
    public string ZipCode { get; set; } = null!;

    [Required]
    [StringLength(100)]
    public string Country { get; set; } = null!;

    /// <summary>
    /// User type - defaults to Guest
    /// </summary>
    public UserTypeEnum UserType { get; set; } = UserTypeEnum.Guest;

    /// <summary>
    /// Date of birth for age verification
    /// </summary>
    public DateOnly? DateOfBirth { get; set; }
}