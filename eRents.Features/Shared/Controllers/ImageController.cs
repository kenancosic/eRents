using eRents.Domain.Shared.Interfaces;
using eRents.Features.Shared.DTOs;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using Microsoft.Extensions.Logging;
using eRents.Features.Shared.Services;

namespace eRents.Features.Shared.Controllers
{
	[ApiController]
	[Route("[controller]")]
	[Authorize] // Require authentication for all image operations
	public class ImageController : ControllerBase
	{
		private readonly IImageService _imageService;
		private readonly ILogger<ImageController> _logger;
		private readonly ICurrentUserService _currentUserService;

		public ImageController(
			IImageService imageService,
			ILogger<ImageController> logger,
			ICurrentUserService currentUserService)
		{
			_imageService = imageService;
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
			var userId = (_currentUserService.GetUserIdAsInt()?.ToString() ?? "unknown");

			return ex switch
			{
				UnauthorizedAccessException unauthorizedException => HandleUnauthorizedError(unauthorizedException, operation, requestId, path, userId),
				ArgumentException validationException => HandleValidationError(validationException, operation, requestId, path, userId),
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

		private IActionResult HandleValidationError(ArgumentException ex, string operation, string requestId, string? path, string userId)
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
		/// Upload image for property, maintenance issue, or review
		/// </summary>
		[HttpPost("upload")]
		[Authorize(Roles = "Landlord")] // Only landlords can upload property images
		public async Task<IActionResult> UploadImage([FromForm] ImageUploadRequest request)
		{
			try
			{
				var userId = (_currentUserService.GetUserIdAsInt()?.ToString() ?? "unknown");
				_logger.LogInformation("Image upload attempt by user {UserId} for property/entity", userId);

				var response = await _imageService.UploadImageAsync(request);

				_logger.LogInformation("Image uploaded successfully: {ImageId} by user {UserId}", response.ImageId, userId);
				return Ok(response);
			}
			catch (Exception ex)
			{
				return HandleStandardError(ex, "Image upload");
			}
		}

		/// <summary>
		/// Get all images for a specific property
		/// </summary>
		[HttpGet("property/{propertyId}")]
		public async Task<IActionResult> GetImagesByProperty(int propertyId)
		{
			try
			{
				var userId = (_currentUserService.GetUserIdAsInt()?.ToString() ?? "unknown");
				_logger.LogInformation("Get property images request for property {PropertyId} by user {UserId}", propertyId, userId);

				var images = await _imageService.GetImagesByPropertyIdAsync(propertyId);

				_logger.LogInformation("Retrieved {ImageCount} images for property {PropertyId}",
					images.Count(), propertyId);
				return Ok(images);
			}
			catch (Exception ex)
			{
				return HandleStandardError(ex, $"Get images for property {propertyId}");
			}
		}

		/// <summary>
		/// Get image by ID and serve as binary data
		/// </summary>
		[HttpGet("{id}")]
		[AllowAnonymous] // Allow public access for displaying images
		public async Task<IActionResult> GetImage(int id)
		{
			try
			{
				var image = await _imageService.GetImageByIdAsync(id);
				if (image == null)
				{
					_logger.LogWarning("Image {ImageId} not found", id);
					return NotFound(new StandardErrorResponse
					{
						Type = "NotFound",
						Message = "Image not found",
						Timestamp = DateTime.UtcNow,
						TraceId = HttpContext.TraceIdentifier,
						Path = Request.Path.Value
					});
				}

				if (image.ImageData == null || image.ImageData.Length == 0)
				{
					_logger.LogWarning("Image {ImageId} has no data available", id);
					return NotFound(new StandardErrorResponse
					{
						Type = "NotFound",
						Message = "Image data not available",
						Timestamp = DateTime.UtcNow,
						TraceId = HttpContext.TraceIdentifier,
						Path = Request.Path.Value
					});
				}

				var contentType = image.ContentType ?? "image/jpeg";
				return File(image.ImageData, contentType, image.FileName ?? $"image_{id}");
			}
			catch (Exception ex)
			{
				return HandleStandardError(ex, $"Get image {id}");
			}
		}

		/// <summary>
		/// Get image thumbnail by ID
		/// </summary>
		[HttpGet("{id}/thumbnail")]
		[AllowAnonymous] // Allow public access for displaying thumbnails
		public async Task<IActionResult> GetThumbnail(int id)
		{
			try
			{
				var image = await _imageService.GetImageByIdAsync(id);
				if (image == null)
				{
					return NotFound(new StandardErrorResponse
					{
						Type = "NotFound",
						Message = "Image not found",
						Timestamp = DateTime.UtcNow,
						TraceId = HttpContext.TraceIdentifier,
						Path = Request.Path.Value
					});
				}

				// Use thumbnail data if available, otherwise fall back to original image
				var imageData = image.ThumbnailData ?? image.ImageData;
				if (imageData == null || imageData.Length == 0)
				{
					return NotFound(new StandardErrorResponse
					{
						Type = "NotFound",
						Message = "Thumbnail data not available",
						Timestamp = DateTime.UtcNow,
						TraceId = HttpContext.TraceIdentifier,
						Path = Request.Path.Value
					});
				}

				var contentType = image.ContentType ?? "image/jpeg";
				var fileName = image.ThumbnailData != null ? $"thumb_{image.FileName}" : image.FileName ?? $"thumb_{id}";
				return File(imageData, contentType, fileName);
			}
			catch (Exception ex)
			{
				return HandleStandardError(ex, $"Get thumbnail for image {id}");
			}
		}

		/// <summary>
		/// Get image information without binary data
		/// </summary>
		[HttpGet("{id}/info")]
		public async Task<IActionResult> GetImageInfo(int id)
		{
			try
			{
				var image = await _imageService.GetImageByIdAsync(id);
				if (image == null)
				{
					return NotFound(new StandardErrorResponse
					{
						Type = "NotFound",
						Message = "Image not found",
						Timestamp = DateTime.UtcNow,
						TraceId = HttpContext.TraceIdentifier,
						Path = Request.Path.Value
					});
				}

				// Return image info without binary data
				var imageInfo = new
				{
					image.ImageId,
					image.FileName,
					image.ContentType,
					image.FileSize,
					image.FileSizeBytes,
					image.PropertyId,
					image.IsCover,
					image.CreatedAt,
					image.UpdatedAt,
					image.Width,
					image.Height
				};

				return Ok(imageInfo);
			}
			catch (Exception ex)
			{
				return HandleStandardError(ex, $"Get image info for {id}");
			}
		}

		/// <summary>
		/// Delete image by ID
		/// </summary>
		[HttpDelete("{id}")]
		[Authorize(Roles = "Landlord")]
		public async Task<IActionResult> DeleteImage(int id)
		{
			try
			{
				var userId = (_currentUserService.GetUserIdAsInt()?.ToString() ?? "unknown");
				_logger.LogInformation("Delete image {ImageId} attempt by user {UserId}",
					id, userId);

				var success = await _imageService.DeleteImageAsync(id);
				if (!success)
				{
					return NotFound(new StandardErrorResponse
					{
						Type = "NotFound",
						Message = "Image not found or could not be deleted",
						Timestamp = DateTime.UtcNow,
						TraceId = HttpContext.TraceIdentifier,
						Path = Request.Path.Value
					});
				}

				_logger.LogInformation("Image {ImageId} deleted successfully by user {UserId}",
					id, userId);
				return NoContent();
			}
			catch (Exception ex)
			{
				return HandleStandardError(ex, $"Delete image {id}");
			}
		}

		/// <summary>
		/// Update image metadata
		/// </summary>
		[HttpPut("{id}")]
		[Authorize(Roles = "Landlord")]
		public async Task<IActionResult> UpdateImage(int id, [FromBody] UpdateImageRequest request)
		{
			try
			{
				var response = await _imageService.UpdateImageMetadataAsync(id, request.IsCover);
				return Ok(response);
			}
			catch (Exception ex)
			{
				return HandleStandardError(ex, $"Update image {id}");
			}
		}

		/// <summary>
		/// Set image as cover image for property
		/// </summary>
		[HttpPost("property/{propertyId}/cover/{imageId}")]
		[Authorize(Roles = "Landlord")]
		public async Task<IActionResult> SetCoverImage(int propertyId, int imageId)
		{
			try
			{
				var success = await _imageService.SetCoverImageAsync(propertyId, imageId);
				if (!success)
				{
					return BadRequest(new StandardErrorResponse
					{
						Type = "Validation",
						Message = "Could not set cover image. Please verify the image belongs to this property.",
						Timestamp = DateTime.UtcNow,
						TraceId = HttpContext.TraceIdentifier,
						Path = Request.Path.Value
					});
				}

				return Ok(new { success = true, message = "Cover image updated successfully" });
			}
			catch (Exception ex)
			{
				return HandleStandardError(ex, $"Set cover image {imageId} for property {propertyId}");
			}
		}
	}

	public class UpdateImageRequest
	{
		public bool? IsCover { get; set; }
	}
}