using eRents.Features.UserManagement.DTOs;
using eRents.Features.UserManagement.Services;
using eRents.Features.Shared.DTOs;
using eRents.Domain.Shared.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace eRents.Features.UserManagement.Controllers;

/// <summary>
/// Authentication controller following new feature architecture
/// Handles login, registration, password operations
/// </summary>
[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly IUserService _userService;
    private readonly IConfiguration _configuration;
    private readonly ILogger<AuthController> _logger;
    private readonly ICurrentUserService _currentUserService;

    public AuthController(
        IUserService userService,
        IConfiguration configuration,
        ILogger<AuthController> logger,
        ICurrentUserService currentUserService)
    {
        _userService = userService;
        _configuration = configuration;
        _logger = logger;
        _currentUserService = currentUserService;
    }

    /// <summary>
    /// User login with JWT token generation
    /// </summary>
    [HttpPost("login")]
    [AllowAnonymous]
    public async Task<ActionResult<LoginResponse>> Login([FromBody] LoginRequest request)
    {
        try
        {
            var clientType = Request.Headers["Client-Type"].FirstOrDefault() ?? "Unknown";
            request.ClientType = clientType;

            _logger.LogInformation("Login attempt for {UsernameOrEmail} from {ClientType}", 
                request.UsernameOrEmail, clientType);

            var userResponse = await _userService.LoginAsync(request);
            if (userResponse != null)
            {
                var token = GenerateJwtToken(userResponse, clientType);
                
                var loginResponse = new LoginResponse
                {
                    Token = token.Token,
                    Expiration = token.Expiration,
                    User = userResponse,
                    Platform = clientType
                };

                _logger.LogInformation("Login successful for user {UserId} from {ClientType}", 
                    userResponse.Id, clientType);

                return Ok(loginResponse);
            }

            _logger.LogWarning("Login failed for {UsernameOrEmail} from {ClientType}", 
                request.UsernameOrEmail, clientType);

            return StatusCode(401, new StandardErrorResponse
            {
                Type = "Authentication",
                Message = "Invalid credentials",
                Timestamp = DateTime.UtcNow,
                TraceId = HttpContext.TraceIdentifier,
                Path = Request.Path.Value
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Login failed for {UsernameOrEmail} from {ClientType}",
                request.UsernameOrEmail, request.ClientType);
                
            return StatusCode(500, new StandardErrorResponse
            {
                Type = "Internal",
                Message = "An unexpected error occurred during login",
                Timestamp = DateTime.UtcNow,
                TraceId = HttpContext.TraceIdentifier,
                Path = Request.Path.Value
            });
        }
    }

    /// <summary>
    /// User registration
    /// </summary>
    [HttpPost("register")]
    [AllowAnonymous]
    public async Task<ActionResult<UserResponse>> Register([FromBody] UserRequest request)
    {
        var clientType = Request.Headers["Client-Type"].FirstOrDefault() ?? "Unknown";
        
        try
        {
            _logger.LogInformation("Registration attempt for {Username} from {ClientType}", 
                request.Username, clientType);

            var userResponse = await _userService.RegisterAsync(request);
            if (userResponse != null)
            {
                _logger.LogInformation("Registration successful for user {UserId} from {ClientType}", 
                    userResponse.Id, clientType);

                return CreatedAtAction(nameof(GetCurrentUser), new { }, userResponse);
            }

            return BadRequest(new StandardErrorResponse
            {
                Type = "Validation",
                Message = "User registration failed",
                Timestamp = DateTime.UtcNow,
                TraceId = HttpContext.TraceIdentifier,
                Path = Request.Path.Value
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Registration failed for {Username} from {ClientType}",
                request.Username, clientType);
                
            return StatusCode(500, new StandardErrorResponse
            {
                Type = "Internal",
                Message = "An unexpected error occurred during registration",
                Timestamp = DateTime.UtcNow,
                TraceId = HttpContext.TraceIdentifier,
                Path = Request.Path.Value
            });
        }
    }

    /// <summary>
    /// Change password for authenticated user
    /// </summary>
    [HttpPost("change-password")]
    [Authorize]
    public async Task<ActionResult> ChangePassword([FromBody] ChangePasswordRequest request)
    {
        var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        var userId = 0;
        
        try
        {
            if (string.IsNullOrEmpty(userIdString) || !int.TryParse(userIdString, out userId))
            {
                return StatusCode(401, new StandardErrorResponse
                {
                    Type = "Authentication",
                    Message = "User ID claim is missing or invalid",
                    Timestamp = DateTime.UtcNow,
                    TraceId = HttpContext.TraceIdentifier,
                    Path = Request.Path.Value
                });
            }

            await _userService.ChangePasswordAsync(userId, request);
            
            _logger.LogInformation("Password changed successfully for user {UserId}", userId);
            
            return Ok(new { message = "Password changed successfully." });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Password change failed for user {UserId}", userId);
            return StatusCode(500, new StandardErrorResponse
            {
                Type = "Internal",
                Message = "An unexpected error occurred while changing password",
                Timestamp = DateTime.UtcNow,
                TraceId = HttpContext.TraceIdentifier,
                Path = Request.Path.Value
            });
        }
    }

    /// <summary>
    /// Forgot password - initiate reset process
    /// </summary>
    [HttpPost("forgot-password")]
    [AllowAnonymous]
    public async Task<ActionResult> ForgotPassword([FromBody] string email)
    {
        try
        {
            _logger.LogInformation("Forgot password request for email: {Email}", email);
            
            await _userService.ForgotPasswordAsync(email);
            
            return Ok(new { message = "If the email exists, a password reset link has been sent." });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Forgot password failed for email: {Email}", email);
            return StatusCode(500, new StandardErrorResponse
            {
                Type = "Internal",
                Message = "An unexpected error occurred while processing password reset request",
                Timestamp = DateTime.UtcNow,
                TraceId = HttpContext.TraceIdentifier,
                Path = Request.Path.Value
            });
        }
    }

    /// <summary>
    /// Reset password with token
    /// </summary>
    [HttpPost("reset-password")]
    [AllowAnonymous]
    public async Task<ActionResult> ResetPassword([FromBody] ResetPasswordRequest request)
    {
        try
        {
            _logger.LogInformation("Password reset attempt for token");
            
            await _userService.ResetPasswordAsync(request);
            
            _logger.LogInformation("Password reset successful");
            
            return Ok(new { message = "Your password has been successfully reset." });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Password reset failed");
            return StatusCode(500, new StandardErrorResponse
            {
                Type = "Internal",
                Message = "An unexpected error occurred while resetting password",
                Timestamp = DateTime.UtcNow,
                TraceId = HttpContext.TraceIdentifier,
                Path = Request.Path.Value
            });
        }
    }

    /// <summary>
    /// Get current authenticated user
    /// </summary>
    [HttpGet("me")]
    [Authorize]
    public async Task<ActionResult<UserResponse>> GetCurrentUser()
    {
        try
        {
            var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdString) || !int.TryParse(userIdString, out var userId))
            {
                return StatusCode(401, new StandardErrorResponse
                {
                    Type = "Authentication",
                    Message = "User ID claim is missing or invalid",
                    Timestamp = DateTime.UtcNow,
                    TraceId = HttpContext.TraceIdentifier,
                    Path = Request.Path.Value
                });
            }

            var userResponse = await _userService.GetByIdAsync(userId);
            if (userResponse == null)
            {
                return NotFound(new StandardErrorResponse
                {
                    Type = "NotFound",
                    Message = "User not found",
                    Timestamp = DateTime.UtcNow,
                    TraceId = HttpContext.TraceIdentifier,
                    Path = Request.Path.Value
                });
            }

            var clientType = User.FindFirst("ClientType")?.Value ?? "Unknown";
            
            _logger.LogInformation("Current user retrieved for user {UserId}", userId);
            
            return Ok(userResponse);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Get current user failed for user {UserId}", 
                User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "unknown");
                
            return StatusCode(500, new StandardErrorResponse
            {
                Type = "Internal",
                Message = "An unexpected error occurred while retrieving user information",
                Timestamp = DateTime.UtcNow,
                TraceId = HttpContext.TraceIdentifier,
                Path = Request.Path.Value
            });
        }
    }

    #region Helper Methods

    /// <summary>
    /// Generate JWT token for authenticated user
    /// </summary>
    private (string Token, DateTime Expiration) GenerateJwtToken(UserResponse user, string clientType)
    {
        var tokenHandler = new JwtSecurityTokenHandler();
        var keyString = _configuration["Jwt:Key"];
        if (string.IsNullOrEmpty(keyString)) 
            throw new InvalidOperationException("JWT Key is not configured.");
        
        var key = Encoding.UTF8.GetBytes(keyString);
        var issuer = _configuration["Jwt:Issuer"];
        var audience = _configuration["Jwt:Audience"];
        
        if (string.IsNullOrEmpty(issuer)) 
            throw new InvalidOperationException("JWT Issuer is not configured.");
        if (string.IsNullOrEmpty(audience)) 
            throw new InvalidOperationException("JWT Audience is not configured.");

        var tokenExpirationString = _configuration["Jwt:TokenExpirationMinutes"];
        var tokenExpirationMinutes = int.TryParse(tokenExpirationString, out var parsedMinutes) ? parsedMinutes : 1440;
        var expires = DateTime.UtcNow.AddMinutes(tokenExpirationMinutes);

        var claims = new List<Claim>
        {
            new Claim(ClaimTypes.Name, user.Username),
            new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new Claim("UserId", user.Id.ToString()),
            new Claim("ClientType", clientType)
        };

        if (!string.IsNullOrEmpty(user.UserTypeName))
        {
            claims.Add(new Claim(ClaimTypes.Role, user.UserTypeName));
        }

        var tokenDescriptor = new SecurityTokenDescriptor
        {
            Subject = new ClaimsIdentity(claims),
            Expires = expires,
            Issuer = issuer,
            Audience = audience,
            SigningCredentials = new SigningCredentials(
                new SymmetricSecurityKey(key), 
                SecurityAlgorithms.HmacSha256Signature)
        };

        var token = tokenHandler.CreateToken(tokenDescriptor);
        var tokenString = tokenHandler.WriteToken(token);

        return (tokenString, expires);
    }

    /// <summary>
    /// Handle standard errors with appropriate HTTP status codes
    /// </summary>
    private IActionResult HandleStandardError(Exception ex, string operation)
    {
        var requestId = HttpContext.TraceIdentifier;
        var path = Request.Path.Value;
        var clientType = Request.Headers["Client-Type"].FirstOrDefault() ?? "Unknown";
        
        return ex switch
        {
            UnauthorizedAccessException => HandleUnauthorizedError(ex, operation, requestId, path, clientType),
            ArgumentException => HandleValidationError(ex, operation, requestId, path, clientType),
            KeyNotFoundException => HandleNotFoundError(ex, operation, requestId, path, clientType),
            _ => HandleGenericError(ex, operation, requestId, path, clientType)
        };
    }

    private IActionResult HandleUnauthorizedError(Exception ex, string operation, string requestId, string? path, string clientType)
    {
        _logger.LogWarning(ex, "{Operation} failed - Unauthorized access from {ClientType} on {Path}", 
            operation, clientType, path);
            
        return StatusCode(403, new StandardErrorResponse
        {
            Type = "Authorization",
            Message = "You don't have permission to perform this operation",
            Timestamp = DateTime.UtcNow,
            TraceId = requestId,
            Path = path
        });
    }

    private IActionResult HandleValidationError(Exception ex, string operation, string requestId, string? path, string clientType)
    {
        _logger.LogWarning(ex, "{Operation} failed - Validation errors from {ClientType} on {Path}", 
            operation, clientType, path);
            
        return BadRequest(new StandardErrorResponse
        {
            Type = "Validation",
            Message = ex.Message,
            Timestamp = DateTime.UtcNow,
            TraceId = requestId,
            Path = path
        });
    }

    private IActionResult HandleNotFoundError(Exception ex, string operation, string requestId, string? path, string clientType)
    {
        _logger.LogWarning(ex, "{Operation} failed - Resource not found from {ClientType} on {Path}", 
            operation, clientType, path);
            
        return NotFound(new StandardErrorResponse
        {
            Type = "NotFound",
            Message = "The requested resource was not found",
            Timestamp = DateTime.UtcNow,
            TraceId = requestId,
            Path = path
        });
    }

    private IActionResult HandleGenericError(Exception ex, string operation, string requestId, string? path, string clientType)
    {
        _logger.LogError(ex, "{Operation} failed - Unexpected error from {ClientType} on {Path}", 
            operation, clientType, path);
            
        return StatusCode(500, new StandardErrorResponse
        {
            Type = "Internal",
            Message = "An unexpected error occurred while processing your request",
            Timestamp = DateTime.UtcNow,
            TraceId = requestId,
            Path = path
        });
    }

    #endregion
} 