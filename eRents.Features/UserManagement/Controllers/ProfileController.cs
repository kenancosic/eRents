using eRents.Features.UserManagement.DTOs;
using eRents.Features.UserManagement.Services;
using eRents.Domain.Shared.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using System.Security.Claims;

namespace eRents.Features.UserManagement.Controllers;

/// <summary>
/// User profile management controller following modular architecture
/// Handles profile operations, image uploads, and account linking
/// </summary>
[ApiController]
[Route("api/[controller]")]
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
    /// Get current user's profile
    /// </summary>
    [HttpGet("me")]
    public async Task<ActionResult<UserResponse>> GetMyProfile()
    {
        try
        {
            var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdString) || !int.TryParse(userIdString, out var userId))
            {
                _logger.LogWarning("Get profile failed - Invalid user ID claim");
                return Unauthorized();
            }

            var userResponse = await _userService.GetByIdAsync(userId);
            if (userResponse == null)
            {
                _logger.LogWarning("Get profile failed - User {UserId} not found", userId);
                return NotFound(new { error = "User not found" });
            }

            _logger.LogInformation("Profile retrieved for user {UserId}", userId);
            return Ok(userResponse);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving user profile");
            return StatusCode(500, new { error = "An error occurred while retrieving your profile" });
        }
    }

    /// <summary>
    /// Update current user's profile
    /// </summary>
    [HttpPut("me")]
    public async Task<ActionResult<UserResponse>> UpdateMyProfile([FromBody] UserUpdateRequest request)
    {
        try
        {
            var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdString) || !int.TryParse(userIdString, out var userId))
            {
                _logger.LogWarning("Update profile failed - Invalid user ID claim");
                return Unauthorized();
            }

            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            var updatedUser = await _userService.UpdateAsync(userId, request);
            
            _logger.LogInformation("Profile updated successfully for user {UserId}", userId);
            return Ok(updatedUser);
        }
        catch (UnauthorizedAccessException)
        {
            return Forbid();
        }
        catch (KeyNotFoundException)
        {
            return NotFound(new { error = "User not found" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating user profile");
            return StatusCode(500, new { error = "An error occurred while updating your profile" });
        }
    }

    /// <summary>
    /// Change current user's password
    /// </summary>
    [HttpPost("change-password")]
    public async Task<ActionResult> ChangePassword([FromBody] ChangePasswordRequest request)
    {
        try
        {
            var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdString) || !int.TryParse(userIdString, out var userId))
            {
                _logger.LogWarning("Change password failed - Invalid user ID claim");
                return Unauthorized();
            }

            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            await _userService.ChangePasswordAsync(userId, request);
            
            _logger.LogInformation("Password changed successfully for user {UserId}", userId);
            
            return Ok(new { message = "Password changed successfully" });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
        catch (UnauthorizedAccessException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error changing password");
            return StatusCode(500, new { error = "An error occurred while changing your password" });
        }
    }

    /// <summary>
    /// Upload profile image
    /// </summary>
    [HttpPost("upload-profile-image")]
    public async Task<ActionResult<object>> UploadProfileImage(IFormFile image)
    {
        try
        {
            var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdString) || !int.TryParse(userIdString, out var userId))
            {
                _logger.LogWarning("Upload profile image failed - Invalid user ID claim");
                return Unauthorized();
            }

            if (image == null || image.Length == 0)
            {
                return BadRequest(new { error = "No image file provided" });
            }

            // Validate image file
            const int maxFileSize = 5 * 1024 * 1024; // 5 MB
            var allowedTypes = new[] { "image/jpeg", "image/jpg", "image/png", "image/gif" };

            if (image.Length > maxFileSize)
            {
                return BadRequest(new { error = "Image file size cannot exceed 5 MB" });
            }

            if (!allowedTypes.Contains(image.ContentType.ToLower()))
            {
                return BadRequest(new { error = "Only JPEG, PNG, and GIF images are allowed" });
            }

            // For now, return a placeholder response
            // TODO: Implement actual image upload logic when ImageService is migrated
            _logger.LogInformation("Profile image upload initiated for user {UserId}", userId);
            
            return Ok(new { 
                message = "Profile image upload functionality will be available after ImageService migration",
                fileName = image.FileName,
                fileSize = image.Length,
                contentType = image.ContentType
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error uploading profile image");
            return StatusCode(500, new { error = "An error occurred while uploading your profile image" });
        }
    }

    /// <summary>
    /// Link PayPal account
    /// </summary>
    [HttpPost("link-paypal")]
    public async Task<ActionResult> LinkPayPal([FromBody] LinkPayPalRequest request)
    {
        try
        {
            var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdString) || !int.TryParse(userIdString, out var userId))
            {
                _logger.LogWarning("Link PayPal failed - Invalid user ID claim");
                return Unauthorized();
            }

            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            if (string.IsNullOrEmpty(request.Email))
            {
                return BadRequest(new { error = "PayPal email is required" });
            }

            await _userService.LinkPayPalAsync(userId, request.Email);
            
            _logger.LogInformation("PayPal account linked successfully for user {UserId}", userId);
            
            return Ok(new { message = "PayPal account linked successfully" });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error linking PayPal account");
            return StatusCode(500, new { error = "An error occurred while linking your PayPal account" });
        }
    }

    /// <summary>
    /// Unlink PayPal account
    /// </summary>
    [HttpPost("unlink-paypal")]
    public async Task<ActionResult> UnlinkPayPal()
    {
        try
        {
            var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdString) || !int.TryParse(userIdString, out var userId))
            {
                _logger.LogWarning("Unlink PayPal failed - Invalid user ID claim");
                return Unauthorized();
            }

            await _userService.UnlinkPayPalAsync(userId);
            
            _logger.LogInformation("PayPal account unlinked successfully for user {UserId}", userId);
            
            return Ok(new { message = "PayPal account unlinked successfully" });
        }
        catch (KeyNotFoundException)
        {
            return NotFound(new { error = "User not found" });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error unlinking PayPal account");
            return StatusCode(500, new { error = "An error occurred while unlinking your PayPal account" });
        }
    }

    /// <summary>
    /// Get user's profile image URL
    /// </summary>
    [HttpGet("profile-image")]
    public async Task<ActionResult<object>> GetProfileImage()
    {
        try
        {
            var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdString) || !int.TryParse(userIdString, out var userId))
            {
                return Unauthorized();
            }

            var user = await _userService.GetByIdAsync(userId);
            if (user == null)
            {
                return NotFound(new { error = "User not found" });
            }

            // Return profile image information
            // TODO: Get actual image URL when ImageService is migrated
            return Ok(new { 
                profileImageId = user.ProfileImageId,
                message = "Profile image URL generation will be available after ImageService migration"
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving profile image");
            return StatusCode(500, new { error = "An error occurred while retrieving your profile image" });
        }
    }
} 