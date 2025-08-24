using System.ComponentModel.DataAnnotations;

namespace eRents.Features.UserManagement.Models;

/// <summary>
/// DTO for changing user password
/// </summary>
public sealed class ChangePasswordRequest
{
	[Required]
	public string OldPassword { get; set; } = null!;

	[Required]
	[MinLength(6, ErrorMessage = "New password must be at least 6 characters long")]
	public string NewPassword { get; set; } = null!;

	[Required]
	[Compare("NewPassword", ErrorMessage = "Passwords do not match")]
	public string ConfirmPassword { get; set; } = null!;
}
