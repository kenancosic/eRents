using System;
using System.Linq;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using eRents.Features.UserManagement.Models;
using eRents.Features.Core;
using eRents.Domain.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Http;

namespace eRents.Features.UserManagement.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize]
public sealed class ProfileController : ControllerBase
{
	private readonly ICrudService<eRents.Domain.Models.User, UserRequest, UserResponse, UserSearch> _service;
	private readonly ILogger<ProfileController> _logger;
	private readonly ERentsContext _context;

	public ProfileController(
			ICrudService<eRents.Domain.Models.User, UserRequest, UserResponse, UserSearch> service,
			ILogger<ProfileController> logger,
			ERentsContext context)
	{
		_service = service;
		_logger = logger;
		_context = context;
	}

	// GET api/profile
	[HttpGet]
	[ProducesResponseType(200, Type = typeof(UserResponse))]
	[ProducesResponseType(401)]
	public async Task<ActionResult<UserResponse>> Get()
	{
		var userId = GetCurrentUserId();
		if (userId == null) return Unauthorized();

		_logger.LogInformation("Fetching profile for current user {UserId}", userId);
		var result = await _service.GetByIdAsync(userId.Value);
		if (result == null) return NotFound();

		return Ok(result);
	}

	// PUT api/profile
	[HttpPut]
	[ProducesResponseType(200, Type = typeof(UserResponse))]
	[ProducesResponseType(400)]
	[ProducesResponseType(401)]
	public async Task<ActionResult<UserResponse>> Update([FromBody] UserRequest request)
	{
		if (!ModelState.IsValid) return BadRequest(ModelState);

		var userId = GetCurrentUserId();
		if (userId == null) return Unauthorized();

		_logger.LogInformation("Updating profile for current user {UserId}", userId);
		var result = await _service.UpdateAsync(userId.Value, request);
		return Ok(result);
	}

	// GET api/profile/saved-properties
	[HttpGet("saved-properties")]
	[ProducesResponseType(200, Type = typeof(List<SavedPropertyResponse>))]
	[ProducesResponseType(401)]
	public async Task<ActionResult<List<SavedPropertyResponse>>> GetSavedProperties()
	{
		var userId = GetCurrentUserId();
		if (userId == null) return Unauthorized();

		var savedProperties = await _context.UserSavedProperties
				.Where(usp => usp.UserId == userId.Value)
				.Include(usp => usp.Property)
				.ThenInclude(p => p.Images)
				.Include(usp => usp.Property)
				.ThenInclude(p => p.Reviews)
				.Include(usp => usp.Property)
				.ThenInclude(p => p.Address)
				.Select(usp => new SavedPropertyResponse
				{
					PropertyId = usp.PropertyId,
					Name = usp.Property.Name,
					Description = usp.Property.Description,
					Price = usp.Property.Price,
					Currency = usp.Property.Currency,
					Rooms = usp.Property.Rooms,
					Area = usp.Property.Area,
					CreatedAt = usp.CreatedAt,
					City = usp.Property.Address != null ? usp.Property.Address.City : null,
					Country = usp.Property.Address != null ? usp.Property.Address.Country : null,
					CoverImageId = usp.Property.Images.OrderBy(i => i.ImageId).FirstOrDefault() != null ?
								usp.Property.Images.OrderBy(i => i.ImageId).FirstOrDefault().ImageId : (int?)null,
					AverageRating = usp.Property.Reviews.Any() ? usp.Property.Reviews.Average(r => r.StarRating) : (decimal?)null,
					ReviewCount = usp.Property.Reviews.Count
				})
				.ToListAsync();

		return Ok(savedProperties);
	}

	// POST api/profile/saved-properties
	[HttpPost("saved-properties")]
	[ProducesResponseType(200)]
	[ProducesResponseType(400)]
	[ProducesResponseType(401)]
	public async Task<ActionResult> SaveProperty([FromBody] SavePropertyRequest request)
	{
		if (!ModelState.IsValid) return BadRequest(ModelState);

		var userId = GetCurrentUserId();
		if (userId == null) return Unauthorized();

		// Check if already saved
		var alreadySaved = await _context.UserSavedProperties
				.AnyAsync(usp => usp.UserId == userId.Value && usp.PropertyId == request.PropertyId);

		if (alreadySaved)
		{
			return Ok(); // Already saved, nothing to do
		}

		// Check if property exists
		var propertyExists = await _context.Properties
				.AnyAsync(p => p.PropertyId == request.PropertyId);

		if (!propertyExists)
		{
			return BadRequest("Property not found");
		}

		// Create saved property record
		var savedProperty = new UserSavedProperty
		{
			UserId = userId.Value,
			PropertyId = request.PropertyId,
			CreatedAt = DateTime.UtcNow,
			UpdatedAt = DateTime.UtcNow
		};

		_context.UserSavedProperties.Add(savedProperty);
		await _context.SaveChangesAsync();

		return Ok();
	}

	// DELETE api/profile/saved-properties/{propertyId}
	[HttpDelete("saved-properties/{propertyId}")]
	[ProducesResponseType(200)]
	[ProducesResponseType(401)]
	[ProducesResponseType(404)]
	public async Task<ActionResult> UnsaveProperty(int propertyId)
	{
		var userId = GetCurrentUserId();
		if (userId == null) return Unauthorized();

		var savedProperty = await _context.UserSavedProperties
				.FirstOrDefaultAsync(usp => usp.UserId == userId.Value && usp.PropertyId == propertyId);

		if (savedProperty == null)
		{
			return NotFound();
		}

		_context.UserSavedProperties.Remove(savedProperty);
		await _context.SaveChangesAsync();

		return Ok();
	}

	// POST api/profile/upload-image
	[HttpPost("upload-image")]
	[Consumes("multipart/form-data")]
	[ProducesResponseType(200, Type = typeof(ProfileImageUploadResponse))]
	[ProducesResponseType(400)]
	[ProducesResponseType(401)]
	public async Task<ActionResult<ProfileImageUploadResponse>> UploadProfileImage(IFormFile file)
	{
		if (file == null || file.Length == 0)
			return BadRequest("No file uploaded");

		var userId = GetCurrentUserId();
		if (userId == null) return Unauthorized();

		// Validate file type
		var allowedTypes = new[] { "image/jpeg", "image/png", "image/gif", "image/webp" };
		if (!allowedTypes.Contains(file.ContentType.ToLowerInvariant()))
			return BadRequest("Invalid file type. Allowed: JPEG, PNG, GIF, WebP");

		// Validate file size (max 5MB)
		if (file.Length > 5 * 1024 * 1024)
			return BadRequest("File too large. Maximum size is 5MB");

		_logger.LogInformation("Uploading profile image for user {UserId}", userId);

		try
		{
			// Read file data
			using var memoryStream = new System.IO.MemoryStream();
			await file.CopyToAsync(memoryStream);
			var imageData = memoryStream.ToArray();

			// Create new image record
			var image = new Image
			{
				ImageData = imageData,
				ContentType = file.ContentType,
				FileName = file.FileName,
				DateUploaded = DateTime.UtcNow,
				IsCover = false
			};

			await _context.Images.AddAsync(image);
			await _context.SaveChangesAsync();

			// Get user and update profile image
			var user = await _context.Users.FindAsync(userId.Value);
			if (user == null)
			{
				// Rollback the image
				_context.Images.Remove(image);
				await _context.SaveChangesAsync();
				return NotFound("User not found");
			}

			// Delete old profile image if exists
			if (user.ProfileImageId.HasValue)
			{
				var oldImage = await _context.Images.FindAsync(user.ProfileImageId.Value);
				if (oldImage != null)
				{
					_context.Images.Remove(oldImage);
				}
			}

			user.ProfileImageId = image.ImageId;
			user.UpdatedAt = DateTime.UtcNow;
			await _context.SaveChangesAsync();

			_logger.LogInformation("Profile image uploaded successfully for user {UserId}, ImageId: {ImageId}", userId, image.ImageId);

			return Ok(new ProfileImageUploadResponse
			{
				ImageId = image.ImageId,
				Success = true,
				Message = "Profile image uploaded successfully"
			});
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error uploading profile image for user {UserId}", userId);
			return StatusCode(500, "An error occurred while uploading the image");
		}
	}

	// Helper to read current user id as int from claims (aligns with Domain expecting int keys)
	private int? GetCurrentUserId()
	{
		var idClaim = User.FindFirst(ClaimTypes.NameIdentifier) ?? User.FindFirst("sub") ?? User.FindFirst("userId");
		if (idClaim == null) return null;
		return int.TryParse(idClaim.Value, out var id) ? id : null;
	}
}

public class ProfileImageUploadResponse
{
	public int ImageId { get; set; }
	public bool Success { get; set; }
	public string? Message { get; set; }
}