using eRents.Application.Services.UserService;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.WebApi.Shared;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using eRents.Shared.Services;
using eRents.Application.Exceptions;
using ValidationException = eRents.Application.Exceptions.ValidationException;

namespace eRents.Controllers
{
	[ApiController]
	[Route("[controller]")]
	[Authorize] // All profile operations require authentication
	public class ProfileController : ControllerBase
	{
		private readonly IUserService _userService;
		private readonly ILogger<ProfileController> _logger;
		private readonly ICurrentUserService _currentUserService;

		public ProfileController(
			IUserService userService,
			ILogger<ProfileController> logger,
			ICurrentUserService currentUserService)
		{
			_userService = userService;
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
			var userId = _currentUserService.UserId ?? "unknown";
			
			return ex switch
			{
				UnauthorizedAccessException unauthorizedException => HandleUnauthorizedError(unauthorizedException, operation, requestId, path, userId),
				ValidationException validationException => HandleValidationError(validationException, operation, requestId, path, userId),
				KeyNotFoundException notFoundException => HandleNotFoundError(notFoundException, operation, requestId, path, userId),
				_ => HandleGenericError(ex, operation, requestId, path, userId)
			};
		}
		
		private IActionResult HandleUnauthorizedError(UnauthorizedAccessException ex, string operation, string requestId, string? path, string userId)
		{
			_logger.LogWarning(ex, "{Operation} failed - Unauthorized access by user {UserId} on {Path}", 
				operation, userId, path);
				
			return StatusCode(403, new StandardErrorResponse
			{
				Type = "Authorization",
				Message = "You don't have permission to perform this operation",
				Timestamp = DateTime.UtcNow,
				TraceId = requestId,
				Path = path
			});
		}
		
		private IActionResult HandleValidationError(ValidationException ex, string operation, string requestId, string? path, string userId)
		{
			_logger.LogWarning(ex, "{Operation} failed - Validation errors for user {UserId} on {Path}", 
				operation, userId, path);
				
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
		
		private IActionResult HandleNotFoundError(KeyNotFoundException ex, string operation, string requestId, string? path, string userId)
		{
			_logger.LogWarning(ex, "{Operation} failed - Resource not found for user {UserId} on {Path}", 
				operation, userId, path);
				
			return NotFound(new StandardErrorResponse
			{
				Type = "NotFound",
				Message = "The requested resource was not found",
				Timestamp = DateTime.UtcNow,
				TraceId = requestId,
				Path = path
			});
		}
		
		private IActionResult HandleGenericError(Exception ex, string operation, string requestId, string? path, string userId)
		{
			_logger.LogError(ex, "{Operation} failed - Unexpected error for user {UserId} on {Path}", 
				operation, userId, path);
				
			return StatusCode(500, new StandardErrorResponse
			{
				Type = "Internal",
				Message = "An unexpected error occurred while processing your request",
				Timestamp = DateTime.UtcNow,
				TraceId = requestId,
				Path = path
			});
		}

		/// <summary>
		/// Get current user's profile
		/// </summary>
		[HttpGet("me")]
		public async Task<IActionResult> GetMyProfile()
		{
			try
			{
				var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
				if (string.IsNullOrEmpty(userIdString) || !int.TryParse(userIdString, out var userId))
				{
					_logger.LogWarning("Get profile failed - Invalid user ID claim");
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
					_logger.LogWarning("Get profile failed - User {UserId} not found", userId);
					return NotFound(new StandardErrorResponse
					{
						Type = "NotFound",
						Message = "User not found",
						Timestamp = DateTime.UtcNow,
						TraceId = HttpContext.TraceIdentifier,
						Path = Request.Path.Value
					});
				}

				_logger.LogInformation("Profile retrieved for user {UserId}", userId);
				return Ok(userResponse);
			}
			catch (Exception ex)
			{
				return HandleStandardError(ex, "Get user profile");
			}
		}

		/// <summary>
		/// Update current user's profile
		/// </summary>
		[HttpPut("me")]
		public async Task<IActionResult> UpdateMyProfile([FromBody] UserUpdateRequest request)
		{
			try
			{
				var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
				if (string.IsNullOrEmpty(userIdString) || !int.TryParse(userIdString, out var userId))
				{
					_logger.LogWarning("Update profile failed - Invalid user ID claim");
					return Unauthorized(new StandardErrorResponse
					{
						Type = "Authentication",
						Message = "User ID claim is missing or invalid",
						Timestamp = DateTime.UtcNow,
						TraceId = HttpContext.TraceIdentifier,
						Path = Request.Path.Value
					});
				}

				var updatedUser = await _userService.UpdateAsync(userId, request);
				
				_logger.LogInformation("Profile updated successfully for user {UserId}", userId);
				return Ok(updatedUser);
			}
			catch (Exception ex)
			{
				return HandleStandardError(ex, "Update user profile");
			}
		}

		/// <summary>
		/// Change current user's password
		/// </summary>
		[HttpPost("change-password")]
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
				return HandleStandardError(ex, "Change password");
			}
		}

		/// <summary>
		/// Upload profile image
		/// </summary>
		[HttpPost("upload-profile-image")]
		public async Task<IActionResult> UploadProfileImage(IFormFile image)
		{
			try
			{
				var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
				if (string.IsNullOrEmpty(userIdString) || !int.TryParse(userIdString, out var userId))
				{
					_logger.LogWarning("Upload profile image failed - Invalid user ID claim");
					return Unauthorized(new StandardErrorResponse
					{
						Type = "Authentication",
						Message = "User ID claim is missing or invalid",
						Timestamp = DateTime.UtcNow,
						TraceId = HttpContext.TraceIdentifier,
						Path = Request.Path.Value
					});
				}

				if (image == null || image.Length == 0)
				{
					_logger.LogWarning("Upload profile image failed - No image file provided for user {UserId}", userId);
					return BadRequest(new StandardErrorResponse
					{
						Type = "Validation",
						Message = "No image file provided",
						Timestamp = DateTime.UtcNow,
						TraceId = HttpContext.TraceIdentifier,
						Path = Request.Path.Value
					});
				}

				// Validate file type
				var allowedTypes = new[] { "image/jpeg", "image/jpg", "image/png", "image/gif" };
				if (!allowedTypes.Contains(image.ContentType.ToLower()))
				{
					_logger.LogWarning("Upload profile image failed - Invalid file type {ContentType} for user {UserId}", 
						image.ContentType, userId);
					return BadRequest(new StandardErrorResponse
					{
						Type = "Validation",
						Message = "Invalid file type. Only JPEG, PNG, and GIF images are allowed",
						Timestamp = DateTime.UtcNow,
						TraceId = HttpContext.TraceIdentifier,
						Path = Request.Path.Value
					});
				}

				// Validate file size (max 5MB)
				if (image.Length > 5 * 1024 * 1024)
				{
					_logger.LogWarning("Upload profile image failed - File too large ({Size} bytes) for user {UserId}", 
						image.Length, userId);
					return BadRequest(new StandardErrorResponse
					{
						Type = "Validation",
						Message = "File size too large. Maximum size is 5MB",
						Timestamp = DateTime.UtcNow,
						TraceId = HttpContext.TraceIdentifier,
						Path = Request.Path.Value
					});
				}

				// TODO: Implement actual image upload service
				// For now, return the current user
				var user = await _userService.GetByIdAsync(userId);
				
				_logger.LogInformation("Profile image upload processed for user {UserId} (placeholder implementation)", userId);
				return Ok(user);
			}
			catch (Exception ex)
			{
				return HandleStandardError(ex, "Upload profile image");
			}
		}

		/// <summary>
		/// Link PayPal account to user profile
		/// </summary>
		[HttpPost("link-paypal")]
		public async Task<IActionResult> LinkPayPal([FromBody] LinkPayPalRequest request)
		{
			try
			{
				var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
				if (string.IsNullOrEmpty(userIdString) || !int.TryParse(userIdString, out var userId))
				{
					_logger.LogWarning("Link PayPal failed - Invalid user ID claim");
					return Unauthorized(new StandardErrorResponse
					{
						Type = "Authentication",
						Message = "User ID claim is missing or invalid",
						Timestamp = DateTime.UtcNow,
						TraceId = HttpContext.TraceIdentifier,
						Path = Request.Path.Value
					});
				}

				if (string.IsNullOrWhiteSpace(request.Email))
				{
					_logger.LogWarning("Link PayPal failed - No email provided for user {UserId}", userId);
					return BadRequest(new StandardErrorResponse
					{
						Type = "Validation",
						Message = "PayPal email is required",
						Timestamp = DateTime.UtcNow,
						TraceId = HttpContext.TraceIdentifier,
						Path = Request.Path.Value
					});
				}

				// Create update request with PayPal information
				var updateRequest = new UserUpdateRequest
				{
					IsPaypalLinked = true,
					PaypalUserIdentifier = request.Email,
					UpdatedAt = DateTime.UtcNow
				};

				var updatedUser = await _userService.UpdateAsync(userId, updateRequest);
				
				_logger.LogInformation("PayPal account linked successfully for user {UserId} with email {PayPalEmail}", 
					userId, request.Email);
				return Ok(updatedUser);
			}
			catch (Exception ex)
			{
				return HandleStandardError(ex, "Link PayPal account");
			}
		}

		/// <summary>
		/// Unlink PayPal account from user profile
		/// </summary>
		[HttpPost("unlink-paypal")]
		public async Task<IActionResult> UnlinkPayPal()
		{
			try
			{
				var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
				if (string.IsNullOrEmpty(userIdString) || !int.TryParse(userIdString, out var userId))
				{
					_logger.LogWarning("Unlink PayPal failed - Invalid user ID claim");
					return Unauthorized(new StandardErrorResponse
					{
						Type = "Authentication",
						Message = "User ID claim is missing or invalid",
						Timestamp = DateTime.UtcNow,
						TraceId = HttpContext.TraceIdentifier,
						Path = Request.Path.Value
					});
				}

				// Create update request to remove PayPal information
				var updateRequest = new UserUpdateRequest
				{
					IsPaypalLinked = false,
					PaypalUserIdentifier = null,
					UpdatedAt = DateTime.UtcNow
				};

				var updatedUser = await _userService.UpdateAsync(userId, updateRequest);
				
				_logger.LogInformation("PayPal account unlinked successfully for user {UserId}", userId);
				return Ok(updatedUser);
			}
			catch (Exception ex)
			{
				return HandleStandardError(ex, "Unlink PayPal account");
			}
		}
	}

	/// <summary>
	/// Request model for linking PayPal account
	/// </summary>
	public class LinkPayPalRequest
	{
		public string Email { get; set; } = string.Empty;
	}
} 