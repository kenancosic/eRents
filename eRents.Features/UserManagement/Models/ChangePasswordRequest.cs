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
	[MinLength(8, ErrorMessage = "Password must be at least 8 characters long")]
	[MaxLength(100, ErrorMessage = "Password must not exceed 100 characters")]
	[RegularExpression(@"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]+$",
		ErrorMessage = "Password must contain at least one lowercase letter, one uppercase letter, one digit, and one special character (@$!%*?&)")]
	public string NewPassword { get; set; } = null!;

	[Required]
	[Compare("NewPassword", ErrorMessage = "Passwords do not match")]
	public string ConfirmPassword { get; set; } = null!;
}
