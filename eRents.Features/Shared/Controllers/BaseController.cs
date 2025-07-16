using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;

namespace eRents.Features.Shared.Controllers;

/// <summary>
/// Base controller providing common functionality for all Features controllers
/// </summary>
[ApiController]
public abstract class BaseController : ControllerBase
{
    /// <summary>
    /// Get current user ID from claims
    /// </summary>
    protected string? GetCurrentUserId()
    {
        return User?.FindFirst("UserId")?.Value ?? User?.FindFirst("sub")?.Value;
    }

    /// <summary>
    /// Get current user role from claims
    /// </summary>
    protected string? GetCurrentUserRole()
    {
        return User?.FindFirst("Role")?.Value ?? User?.FindFirst("role")?.Value;
    }

    /// <summary>
    /// Get current username from claims
    /// </summary>
    protected string? GetCurrentUserName()
    {
        return User?.FindFirst("UserName")?.Value ?? User?.FindFirst("name")?.Value;
    }

    /// <summary>
    /// Check if current user has specific role
    /// </summary>
    protected bool HasRole(string role)
    {
        var userRole = GetCurrentUserRole();
        return string.Equals(userRole, role, StringComparison.OrdinalIgnoreCase);
    }

    /// <summary>
    /// Check if current user is authenticated
    /// </summary>
    protected bool IsAuthenticated()
    {
        return User?.Identity?.IsAuthenticated == true;
    }

    /// <summary>
    /// Create standardized error response
    /// </summary>
    protected IActionResult CreateErrorResponse(string message, int statusCode = 400)
    {
        return StatusCode(statusCode, new { error = message });
    }

    /// <summary>
    /// Create standardized success response
    /// </summary>
    protected IActionResult CreateSuccessResponse(object? data = null, string? message = null)
    {
        var response = new
        {
            success = true,
            message = message ?? "Operation completed successfully",
            data = data
        };
        return Ok(response);
    }
} 