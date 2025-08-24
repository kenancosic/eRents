using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using eRents.Features.UserManagement.Models;
using eRents.Features.Core;
using Microsoft.AspNetCore.Authorization;
using eRents.Features.UserManagement.Interfaces;
using eRents.Domain.Shared.Interfaces;

namespace eRents.Features.UserManagement.Controllers;

[Route("api/[controller]")]
[ApiController]
public sealed class UsersController : CrudController<eRents.Domain.Models.User, UserRequest, UserResponse, UserSearch>
{
    private readonly IUserService _userService;

    private readonly ICurrentUserService _currentUser;

    public UsersController(
        IUserService userService,
        ILogger<UsersController> logger,
        ICurrentUserService currentUser)
        : base(userService, logger)
    {
        _userService = userService;
        _currentUser = currentUser;
    }

    /// <summary>
    /// Changes the password for the currently authenticated user
    /// </summary>
    [HttpPut("change-password")] // derive userId from JWT claims to prevent IDOR
    [Authorize]
    [ProducesResponseType(200)]
    [ProducesResponseType(400)]
    [ProducesResponseType(401)]
    [ProducesResponseType(403)]
    [ProducesResponseType(500)]
    public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordRequest request)
    {
        if (!ModelState.IsValid)
        {
            return BadRequest(ModelState);
        }

        try
        {
            // Resolve userId from claims
            var userId = _currentUser.GetUserIdAsInt();
            if (!userId.HasValue)
            {
                return Unauthorized(new { message = "User context missing or not authenticated" });
            }

            // Attempt to change password
            var success = await _userService.ChangePasswordAsync(userId.Value, request.OldPassword, request.NewPassword);

            if (!success)
            {
                return BadRequest(new { message = "Current password is incorrect or user not found" });
            }

            return Ok(new { message = "Password changed successfully" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error changing password for current user");
            return StatusCode(500, new { message = "An error occurred while changing password" });
        }
    }
}