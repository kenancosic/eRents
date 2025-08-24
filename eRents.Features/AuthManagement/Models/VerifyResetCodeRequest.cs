namespace eRents.Features.AuthManagement.Models;

/// <summary>
/// Request payload for verifying reset code without changing password
/// </summary>
public sealed class VerifyResetCodeRequest
{
    public string Email { get; set; } = null!;
    public string Code { get; set; } = null!;
}
