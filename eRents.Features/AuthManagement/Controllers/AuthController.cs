using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using eRents.Features.AuthManagement.Interfaces;
using eRents.Features.AuthManagement.Models;

namespace eRents.Features.AuthManagement.Controllers;

/// <summary>
/// Controller for authentication operations
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Produces("application/json")]
public sealed class AuthController : ControllerBase
{
    private readonly IAuthService _authService;
    private readonly ILogger<AuthController> _logger;

    public AuthController(IAuthService authService, ILogger<AuthController> logger)
    {
        _authService = authService ?? throw new ArgumentNullException(nameof(authService));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
    }

    /// <summary>
    /// Authenticates a user and returns JWT tokens
    /// </summary>
    [HttpPost("login")]
    [AllowAnonymous]
    [ProducesResponseType(200, Type = typeof(AuthResponse))]
    [ProducesResponseType(400)]
    [ProducesResponseType(401)]
    [ProducesResponseType(500)]
    public async Task<IActionResult> Login([FromBody] LoginRequest request)
    {
        if (!ModelState.IsValid)
        {
            _logger.LogWarning("Invalid login request model");
            return BadRequest(ModelState);
        }

        try
        {
            var result = await _authService.LoginAsync(request);
            
            if (result == null)
            {
                _logger.LogWarning("Login failed for username: {Username}", request.Username);
                return Unauthorized(new { message = "Invalid username or password" });
            }

            _logger.LogInformation("Login successful for username: {Username}", request.Username);
            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during login for username: {Username}", request.Username);
            return StatusCode(500, new { message = "An error occurred during login" });
        }
    }

    /// <summary>
    /// Registers a new user account
    /// </summary>
    [HttpPost("register")]
    [AllowAnonymous]
    [ProducesResponseType(201, Type = typeof(AuthResponse))]
    [ProducesResponseType(400)]
    [ProducesResponseType(409)] // Conflict for existing username/email
    [ProducesResponseType(500)]
    public async Task<IActionResult> Register([FromBody] RegisterRequest request)
    {
        if (!ModelState.IsValid)
        {
            _logger.LogWarning("Invalid registration request model");
            return BadRequest(ModelState);
        }

        try
        {
            var result = await _authService.RegisterAsync(request);
            _logger.LogInformation("Registration successful for username: {Username}", request.Username);
            return CreatedAtAction(nameof(Login), result);
        }
        catch (InvalidOperationException ex)
        {
            _logger.LogWarning(ex, "Registration conflict for username: {Username}", request.Username);
            return Conflict(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during registration for username: {Username}", request.Username);
            return StatusCode(500, new { message = "An error occurred during registration" });
        }
    }

    /// <summary>
    /// Initiates password reset by emailing a 6-digit reset code
    /// </summary>
    [HttpPost("forgot-password")]
    [AllowAnonymous]
    [ProducesResponseType(200)]
    [ProducesResponseType(400)]
    [ProducesResponseType(500)]
    public async Task<IActionResult> ForgotPassword([FromBody] ForgotPasswordRequest request)
    {
        if (!ModelState.IsValid)
        {
            _logger.LogWarning("Invalid forgot password request model");
            return BadRequest(ModelState);
        }

        try
        {
            await _authService.ForgotPasswordAsync(request);
            _logger.LogInformation("Password reset requested for email: {Email}", request.Email);
            
            // Always return success to prevent email enumeration
            return Ok(new { message = "If the email exists, a password reset code has been sent." });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during password reset request for email: {Email}", request.Email);
            return StatusCode(500, new { message = "An error occurred while processing your request" });
        }
    }

    /// <summary>
    /// Resets password using reset code
    /// </summary>
    [HttpPost("reset-password")]
    [AllowAnonymous]
    [ProducesResponseType(200)]
    [ProducesResponseType(400)]
    [ProducesResponseType(500)]
    public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordRequest request)
    {
        if (!ModelState.IsValid)
        {
            _logger.LogWarning("Invalid reset password request model");
            return BadRequest(ModelState);
        }

        try
        {
            var success = await _authService.ResetPasswordAsync(request);
            
            if (!success)
            {
                _logger.LogWarning("Password reset failed for email: {Email}", request.Email);
                return BadRequest(new { message = "Invalid or expired reset code" });
            }

            _logger.LogInformation("Password reset successful for email: {Email}", request.Email);
            return Ok(new { message = "Password has been reset successfully" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during password reset for email: {Email}", request.Email);
            return StatusCode(500, new { message = "An error occurred while resetting password" });
        }
    }

    /// <summary>
    /// Refreshes JWT access token using refresh token
    /// </summary>
    [HttpPost("refresh-token")]
    [AllowAnonymous]
    [ProducesResponseType(200, Type = typeof(AuthResponse))]
    [ProducesResponseType(400)]
    [ProducesResponseType(401)]
    [ProducesResponseType(500)]
    public async Task<IActionResult> RefreshToken([FromBody] RefreshTokenRequest request)
    {
        if (string.IsNullOrEmpty(request?.RefreshToken))
        {
            return BadRequest(new { message = "Refresh token is required" });
        }

        try
        {
            var result = await _authService.RefreshTokenAsync(request.RefreshToken);
            
            if (result == null)
            {
                _logger.LogWarning("Refresh token failed for token: {Token}", request.RefreshToken[..Math.Min(10, request.RefreshToken.Length)]);
                return Unauthorized(new { message = "Invalid or expired refresh token" });
            }

            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during token refresh");
            return StatusCode(500, new { message = "An error occurred while refreshing token" });
        }
    }

    /// <summary>
    /// Checks if username is available for registration
    /// </summary>
    [HttpGet("check-username/{username}")]
    [AllowAnonymous]
    [ProducesResponseType(200, Type = typeof(AvailabilityResponse))]
    [ProducesResponseType(400)]
    [ProducesResponseType(500)]
    public async Task<IActionResult> CheckUsernameAvailability(string username)
    {
        if (string.IsNullOrWhiteSpace(username))
        {
            return BadRequest(new { message = "Username is required" });
        }

        try
        {
            var isAvailable = await _authService.IsUsernameAvailableAsync(username);
            return Ok(new AvailabilityResponse { IsAvailable = isAvailable });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error checking username availability for: {Username}", username);
            return StatusCode(500, new { message = "An error occurred while checking availability" });
        }
    }

    /// <summary>
    /// Checks if email is available for registration
    /// </summary>
    [HttpGet("check-email/{email}")]
    [AllowAnonymous]
    [ProducesResponseType(200, Type = typeof(AvailabilityResponse))]
    [ProducesResponseType(400)]
    [ProducesResponseType(500)]
    public async Task<IActionResult> CheckEmailAvailability(string email)
    {
        if (string.IsNullOrWhiteSpace(email))
        {
            return BadRequest(new { message = "Email is required" });
        }

        try
        {
            var isAvailable = await _authService.IsEmailAvailableAsync(email);
            return Ok(new AvailabilityResponse { IsAvailable = isAvailable });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error checking email availability for: {Email}", email);
            return StatusCode(500, new { message = "An error occurred while checking availability" });
        }
    }
}

/// <summary>
/// Request model for refresh token operation
/// </summary>
public sealed class RefreshTokenRequest
{
    public string RefreshToken { get; set; } = null!;
}

/// <summary>
/// Response model for availability checks
/// </summary>
public sealed class AvailabilityResponse
{
    public bool IsAvailable { get; set; }
}