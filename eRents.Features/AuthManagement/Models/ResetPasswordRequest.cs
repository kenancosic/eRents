using System.ComponentModel.DataAnnotations;

namespace eRents.Features.AuthManagement.Models;

/// <summary>
/// Request model for resetting password with a verification code sent via email
/// </summary>
public sealed class ResetPasswordRequest
{
    [Required]
    [EmailAddress]
    [StringLength(100)]
    public string Email { get; set; } = null!;

    [Required]
    public string ResetCode { get; set; } = null!;

    [Required]
    [StringLength(100, MinimumLength = 8)]
    [RegularExpression(@"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]", 
        ErrorMessage = "Password must contain at least one lowercase letter, one uppercase letter, one digit, and one special character.")]
    public string NewPassword { get; set; } = null!;

    [Required]
    [Compare("NewPassword")]
    public string ConfirmPassword { get; set; } = null!;
}