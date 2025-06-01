using eRents.Application.Service.UserService;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.WebApi.Shared;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace eRents.Controllers
{
	[ApiController]
	[Route("[controller]")]
	[Authorize] // All profile operations require authentication
	public class ProfileController : ControllerBase
	{
		private readonly IUserService _userService;

		public ProfileController(IUserService userService)
		{
			_userService = userService;
		}

		/// <summary>
		/// Get current user's profile
		/// </summary>
		[HttpGet("me")]
		public async Task<ActionResult<UserResponse>> GetMyProfile()
		{
			var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
			if (string.IsNullOrEmpty(userIdString) || !int.TryParse(userIdString, out var userId))
			{
				return Unauthorized("User ID claim is missing or invalid.");
			}

			var userResponse = await _userService.GetByIdAsync(userId);
			if (userResponse == null)
			{
				return NotFound("User not found.");
			}

			return Ok(userResponse);
		}

		/// <summary>
		/// Update current user's profile
		/// </summary>
		[HttpPut("me")]
		public async Task<ActionResult<UserResponse>> UpdateMyProfile([FromBody] UserUpdateRequest request)
		{
			var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
			if (string.IsNullOrEmpty(userIdString) || !int.TryParse(userIdString, out var userId))
			{
				return Unauthorized("User ID claim is missing or invalid.");
			}

			try
			{
				var updatedUser = await _userService.UpdateAsync(userId, request);
				return Ok(updatedUser);
			}
			catch (Exception ex)
			{
				return BadRequest(new { message = ex.Message });
			}
		}

		/// <summary>
		/// Change current user's password
		/// </summary>
		[HttpPost("change-password")]
		public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordRequest request)
		{
			var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
			if (string.IsNullOrEmpty(userIdString) || !int.TryParse(userIdString, out var userId))
			{
				return Unauthorized("User ID claim is missing or invalid.");
			}

			try
			{
				await _userService.ChangePasswordAsync(userId, request);
				return Ok(new { message = "Password changed successfully." });
			}
			catch (Exception ex)
			{
				return BadRequest(new { message = ex.Message });
			}
		}

		/// <summary>
		/// Upload profile image
		/// </summary>
		[HttpPost("upload-profile-image")]
		public async Task<ActionResult<UserResponse>> UploadProfileImage(IFormFile image)
		{
			var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
			if (string.IsNullOrEmpty(userIdString) || !int.TryParse(userIdString, out var userId))
			{
				return Unauthorized("User ID claim is missing or invalid.");
			}

			if (image == null || image.Length == 0)
			{
				return BadRequest("No image file provided.");
			}

			// Validate file type
			var allowedTypes = new[] { "image/jpeg", "image/jpg", "image/png", "image/gif" };
			if (!allowedTypes.Contains(image.ContentType.ToLower()))
			{
				return BadRequest("Invalid file type. Only JPEG, PNG, and GIF images are allowed.");
			}

			// Validate file size (max 5MB)
			if (image.Length > 5 * 1024 * 1024)
			{
				return BadRequest("File size too large. Maximum size is 5MB.");
			}

			try
			{
				// TODO: Implement actual image upload service
				// For now, return a placeholder response
				var user = await _userService.GetByIdAsync(userId);
				return Ok(user);
			}
			catch (Exception ex)
			{
				return BadRequest(new { message = ex.Message });
			}
		}

		/// <summary>
		/// Link PayPal account to user profile
		/// </summary>
		[HttpPost("link-paypal")]
		public async Task<ActionResult<UserResponse>> LinkPayPal([FromBody] LinkPayPalRequest request)
		{
			var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
			if (string.IsNullOrEmpty(userIdString) || !int.TryParse(userIdString, out var userId))
			{
				return Unauthorized("User ID claim is missing or invalid.");
			}

			if (string.IsNullOrWhiteSpace(request.Email))
			{
				return BadRequest("PayPal email is required.");
			}

			try
			{
				// Create update request with PayPal information
				var updateRequest = new UserUpdateRequest
				{
					IsPaypalLinked = true,
					PaypalUserIdentifier = request.Email,
					UpdatedAt = DateTime.UtcNow
				};

				var updatedUser = await _userService.UpdateAsync(userId, updateRequest);
				return Ok(updatedUser);
			}
			catch (Exception ex)
			{
				return BadRequest(new { message = ex.Message });
			}
		}

		/// <summary>
		/// Unlink PayPal account from user profile
		/// </summary>
		[HttpPost("unlink-paypal")]
		public async Task<ActionResult<UserResponse>> UnlinkPayPal()
		{
			var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
			if (string.IsNullOrEmpty(userIdString) || !int.TryParse(userIdString, out var userId))
			{
				return Unauthorized("User ID claim is missing or invalid.");
			}

			try
			{
				// Create update request to remove PayPal information
				var updateRequest = new UserUpdateRequest
				{
					IsPaypalLinked = false,
					PaypalUserIdentifier = null,
					UpdatedAt = DateTime.UtcNow
				};

				var updatedUser = await _userService.UpdateAsync(userId, updateRequest);
				return Ok(updatedUser);
			}
			catch (Exception ex)
			{
				return BadRequest(new { message = ex.Message });
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