using eRents.Application.Service.UserService;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using eRents.Application.Exceptions;
using Microsoft.AspNetCore.Authorization;
using eRents.Shared.Services;

namespace eRents.WebApi.Controllers
{
	[ApiController]
	[Route("[controller]")]
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
		/// Handles all types of exceptions with appropriate HTTP status codes and standardized error responses
		/// </summary>
		private IActionResult HandleStandardError(Exception ex, string operation)
		{
			var requestId = HttpContext.TraceIdentifier;
			var path = Request.Path.Value;
			var clientType = Request.Headers["Client-Type"].FirstOrDefault() ?? "Unknown";
			
			return ex switch
			{
				UserNotFoundException => HandleAuthenticationError(ex, operation, requestId, path, clientType),
				InvalidPasswordException => HandleAuthenticationError(ex, operation, requestId, path, clientType),
				ValidationException validationEx => HandleValidationError(validationEx, operation, requestId, path, clientType),
				UnauthorizedAccessException unauthorizedEx => HandleUnauthorizedError(unauthorizedEx, operation, requestId, path, clientType),
				_ => HandleGenericError(ex, operation, requestId, path, clientType)
			};
		}

		private IActionResult HandleAuthenticationError(Exception ex, string operation, string requestId, string? path, string clientType)
		{
			_logger.LogWarning(ex, "{Operation} failed - Authentication error from {ClientType} on {Path}", 
				operation, clientType, path);
				
			return Unauthorized(new StandardErrorResponse
			{
				Type = "Authentication",
				Message = "Invalid credentials",
				Timestamp = DateTime.UtcNow,
				TraceId = requestId,
				Path = path
			});
		}

		private IActionResult HandleValidationError(ValidationException ex, string operation, string requestId, string? path, string clientType)
		{
			_logger.LogWarning(ex, "{Operation} failed - Validation error from {ClientType} on {Path}", 
				operation, clientType, path);
				
			var validationErrors = new Dictionary<string, string[]>();
			if (!string.IsNullOrEmpty(ex.Message))
			{
				validationErrors["general"] = new[] { ex.Message };
			}
				
			return BadRequest(new StandardErrorResponse
			{
				Type = "Validation",
				Message = "One or more validation errors occurred",
				ValidationErrors = validationErrors,
				Timestamp = DateTime.UtcNow,
				TraceId = requestId,
				Path = path
			});
		}

		private IActionResult HandleUnauthorizedError(UnauthorizedAccessException ex, string operation, string requestId, string? path, string clientType)
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

		[HttpPost("Login")]
		public async Task<IActionResult> Login([FromBody] LoginRequest loginRequest)
		{
			try
			{
				var clientType = Request.Headers["Client-Type"].FirstOrDefault() ?? "Unknown";
				
				_logger.LogInformation("Login attempt for {UsernameOrEmail} from {ClientType}", 
					loginRequest.UsernameOrEmail, clientType);

				var userResponse = await _userService.LoginAsync(loginRequest.UsernameOrEmail, loginRequest.Password);

				if (userResponse != null)
				{
					var tokenHandler = new JwtSecurityTokenHandler();
					var keyString = _configuration["Jwt:Key"];
					if (string.IsNullOrEmpty(keyString)) throw new InvalidOperationException("JWT Key is not configured.");
					var key = Encoding.UTF8.GetBytes(keyString);

					var issuer = _configuration["Jwt:Issuer"];
					var audience = _configuration["Jwt:Audience"];
					if (string.IsNullOrEmpty(issuer)) throw new InvalidOperationException("JWT Issuer is not configured.");
					if (string.IsNullOrEmpty(audience)) throw new InvalidOperationException("JWT Audience is not configured.");

					var tokenExpirationMinutes = _configuration.GetValue<int?>("Jwt:TokenExpirationMinutes");
					var expires = DateTime.UtcNow.AddMinutes(tokenExpirationMinutes ?? 1440);

					var claims = new List<Claim>
					{
						new Claim(ClaimTypes.Name, userResponse.Username ?? ""),
						new Claim(ClaimTypes.NameIdentifier, userResponse.Id.ToString()),
						new Claim("UserId", userResponse.Id.ToString()),
						new Claim("ClientType", clientType)
					};

					if (!string.IsNullOrEmpty(userResponse.Role))
					{
						claims.Add(new Claim(ClaimTypes.Role, userResponse.Role));
					}
					else
					{
						_logger.LogWarning("Role is missing for user {Username}. Token generated without role claim.", userResponse.Username);
					}

					var tokenDescriptor = new SecurityTokenDescriptor
					{
						Subject = new ClaimsIdentity(claims),
						Expires = expires,
						Issuer = issuer,
						Audience = audience,
						SigningCredentials = new SigningCredentials(new SymmetricSecurityKey(key), SecurityAlgorithms.HmacSha256Signature)
					};
					var token = tokenHandler.CreateToken(tokenDescriptor);
					var tokenString = tokenHandler.WriteToken(token);

					var loginResponse = new LoginResponse
					{
						Token = tokenString,
						Expiration = token.ValidTo,
						User = userResponse,
						Platform = clientType
					};

					_logger.LogInformation("Login successful for user {UserId} from {ClientType}", 
						userResponse.Id, clientType);

					return Ok(loginResponse);
				}

				return Unauthorized(new StandardErrorResponse
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
				return HandleStandardError(ex, "User login");
			}
		}

		[HttpPost("Register")]
		public async Task<IActionResult> Register([FromBody] UserInsertRequest request)
		{
			try
			{
				var clientType = Request.Headers["Client-Type"].FirstOrDefault() ?? "Unknown";
				
				_logger.LogInformation("Registration attempt for {Username} from {ClientType}", 
					request.Username, clientType);

				var userResponse = await _userService.RegisterAsync(request);
				if (userResponse != null)
				{
					_logger.LogInformation("Registration successful for user {UserId} from {ClientType}", 
						userResponse.Id, clientType);

					return Ok(new { User = userResponse, Platform = clientType });
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
				return HandleStandardError(ex, "User registration");
			}
		}

		[HttpPost("ChangePassword")]
		[Authorize]
		public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordRequest request)
		{
			try
			{
				var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
				if (string.IsNullOrEmpty(userIdString) || !int.TryParse(userIdString, out var userId))
				{
					_logger.LogWarning("Change password failed - Invalid user ID claim");
					return Unauthorized(new StandardErrorResponse
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
				return HandleStandardError(ex, "Password change");
			}
		}

		[HttpPost("forgot-password")]
		[AllowAnonymous]
		public async Task<IActionResult> ForgotPassword([FromBody] string email)
		{
			try
			{
				_logger.LogInformation("Forgot password request for email: {Email}", email);
				
				await _userService.ForgotPasswordAsync(email);
				
				return Ok(new { message = "If the email exists, a password reset link has been sent." });
			}
			catch (Exception ex)
			{
				return HandleStandardError(ex, "Forgot password");
			}
		}

		[HttpPost("ResetPassword")]
		public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordRequest request)
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
				return HandleStandardError(ex, "Password reset");
			}
		}

		[HttpGet("Me")]
		[Authorize]
		public async Task<IActionResult> GetCurrentUser()
		{
			try
			{
				var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
				if (string.IsNullOrEmpty(userIdString) || !int.TryParse(userIdString, out var userId))
				{
					_logger.LogWarning("Get current user failed - Invalid user ID claim");
					return Unauthorized(new StandardErrorResponse
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
					_logger.LogWarning("Get current user failed - User {UserId} not found", userId);
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
				
				return Ok(new { User = userResponse, Platform = clientType });
			}
			catch (Exception ex)
			{
				return HandleStandardError(ex, "Get current user");
			}
		}
	}
}
