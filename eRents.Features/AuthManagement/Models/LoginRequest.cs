using System.ComponentModel.DataAnnotations;

namespace eRents.Features.AuthManagement.Models;

/// <summary>
/// Request model for user login. Accepts either Username or Email, and Password.
/// </summary>
public sealed class LoginRequest
{
    /// <summary>
    /// Username to login with (optional if Email is provided)
    /// </summary>
    public string? Username { get; set; }

    /// <summary>
    /// Email to login with (optional if Username is provided)
    /// </summary>
    public string? Email { get; set; }

    [Required]
    [StringLength(100, MinimumLength = 6)]
    public string Password { get; set; } = null!;

    /// <summary>
    /// Whether to remember the user for extended login duration
    /// </summary>
    public bool RememberMe { get; set; } = false;
}