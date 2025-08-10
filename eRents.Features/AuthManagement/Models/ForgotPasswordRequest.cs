using System.ComponentModel.DataAnnotations;

namespace eRents.Features.AuthManagement.Models;

/// <summary>
/// Request model for forgot password functionality
/// </summary>
public sealed class ForgotPasswordRequest
{
    [Required]
    [EmailAddress]
    [StringLength(100)]
    public string Email { get; set; } = null!;
}