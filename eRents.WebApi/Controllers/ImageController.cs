using eRents.Application.Services.ImageService;
using eRents.Shared.DTO.Requests;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using eRents.Shared.Services;
using eRents.Shared.DTO.Response;
using eRents.Application.Exceptions;
using ValidationException = eRents.Application.Exceptions.ValidationException;

namespace eRents.WebApi.Controllers
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
		/// Upload image for property, maintenance issue, or review
		/// </summary>
		[HttpPost("upload")]
		[Authorize(Roles = "Landlord")] // Only landlords can upload property images
		public async Task<IActionResult> UploadImage([FromForm] ImageUploadRequest request)
		{
			try
			{
				_logger.LogInformation("Image upload attempt by user {UserId} for property/entity", 
					_currentUserService.UserId ?? "unknown");

				var response = await _imageService.UploadImageAsync(request);
				
				_logger.LogInformation("Image uploaded successfully: {ImageId} by user {UserId}", 
					response.ImageId, _currentUserService.UserId ?? "unknown");
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
				_logger.LogInformation("Get property images request for property {PropertyId} by user {UserId}", 
					propertyId, _currentUserService.UserId ?? "unknown");

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
				return File(image.ImageData, contentType, image.FileName);
			}
			catch (Exception ex)
			{
				return HandleStandardError(ex, $"Get image {id}");
			}
		}

		/// <summary>
		/// Get thumbnail version of image by ID
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
					_logger.LogWarning("Thumbnail for image {ImageId} not found", id);
					return NotFound(new StandardErrorResponse
					{
						Type = "NotFound",
						Message = "Image not found",
						Timestamp = DateTime.UtcNow,
						TraceId = HttpContext.TraceIdentifier,
						Path = Request.Path.Value
					});
				}

				// Use thumbnail if available, otherwise fall back to original
				var imageData = image.ThumbnailData ?? image.ImageData;
				if (imageData == null || imageData.Length == 0)
				{
					_logger.LogWarning("Thumbnail for image {ImageId} has no data available", id);
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
				return File(imageData, contentType, $"thumb_{image.FileName}");
			}
			catch (Exception ex)
			{
				return HandleStandardError(ex, $"Get thumbnail for image {id}");
			}
		}

		/// <summary>
		/// Get image metadata without binary data
		/// </summary>
		[HttpGet("{id}/info")]
		public async Task<IActionResult> GetImageInfo(int id)
		{
			try
			{
				_logger.LogInformation("Get image info request for image {ImageId} by user {UserId}", 
					id, _currentUserService.UserId ?? "unknown");

				var image = await _imageService.GetImageByIdAsync(id);
				if (image == null)
				{
					_logger.LogWarning("Image info for image {ImageId} not found", id);
					return NotFound(new StandardErrorResponse
					{
						Type = "NotFound",
						Message = "Image not found",
						Timestamp = DateTime.UtcNow,
						TraceId = HttpContext.TraceIdentifier,
						Path = Request.Path.Value
					});
				}

				var imageInfo = new
				{
					ImageId = image.ImageId,
					FileName = image.FileName,
					ContentType = image.ContentType,
					DateUploaded = image.DateUploaded,
					Width = image.Width,
					Height = image.Height,
					FileSizeBytes = image.FileSizeBytes,
					IsCover = image.IsCover,
					HasThumbnail = image.ThumbnailData != null && image.ThumbnailData.Length > 0,
					Url = $"/Image/{image.ImageId}",
					ThumbnailUrl = $"/Image/{image.ImageId}/thumbnail"
				};

				return Ok(imageInfo);
			}
			catch (Exception ex)
			{
				return HandleStandardError(ex, $"Get image info for image {id}");
			}
		}

		/// <summary>
		/// Delete image by ID (only for property owners or image uploaders)
		/// </summary>
		[HttpDelete("{id}")]
		[Authorize(Roles = "Landlord")]
		public async Task<IActionResult> DeleteImage(int id)
		{
			try
			{
				_logger.LogInformation("Delete image request for image {ImageId} by user {UserId}", 
					id, _currentUserService.UserId ?? "unknown");

				var success = await _imageService.DeleteImageAsync(id);
				if (!success)
				{
					_logger.LogWarning("Delete image failed - Image {ImageId} not found", id);
					return NotFound(new StandardErrorResponse
					{
						Type = "NotFound",
						Message = "Image not found",
						Timestamp = DateTime.UtcNow,
						TraceId = HttpContext.TraceIdentifier,
						Path = Request.Path.Value
					});
				}

				_logger.LogInformation("Image {ImageId} deleted successfully by user {UserId}", 
					id, _currentUserService.UserId ?? "unknown");
				return Ok(new { message = "Image deleted successfully" });
			}
			catch (Exception ex)
			{
				return HandleStandardError(ex, $"Delete image {id}");
			}
		}

		/// <summary>
		/// Update image metadata (cover status, description, etc.)
		/// </summary>
		[HttpPut("{id}")]
		[Authorize(Roles = "Landlord")]
		public async Task<IActionResult> UpdateImage(int id, [FromBody] UpdateImageRequest request)
		{
			try
			{
				_logger.LogInformation("Update image metadata request for image {ImageId} by user {UserId}", 
					id, _currentUserService.UserId ?? "unknown");

				var updatedImage = await _imageService.UpdateImageMetadataAsync(id, request.IsCover, request.Description);
				
				_logger.LogInformation("Image metadata updated successfully for image {ImageId}", id);
				return Ok(updatedImage);
			}
			catch (Exception ex)
			{
				return HandleStandardError(ex, $"Update image metadata for image {id}");
			}
		}

		/// <summary>
		/// Set property cover image
		/// </summary>
		[HttpPost("property/{propertyId}/cover/{imageId}")]
		[Authorize(Roles = "Landlord")]
		public async Task<IActionResult> SetCoverImage(int propertyId, int imageId)
		{
			try
			{
				_logger.LogInformation("Set cover image request: property {PropertyId}, image {ImageId} by user {UserId}", 
					propertyId, imageId, _currentUserService.UserId ?? "unknown");

				// For now, use the update metadata method with IsCover = true
				var updatedImage = await _imageService.UpdateImageMetadataAsync(imageId, true, null);
				
				_logger.LogInformation("Cover image set successfully for property {PropertyId}, image {ImageId}", 
					propertyId, imageId);
				return Ok(new { message = "Cover image set successfully", image = updatedImage });
			}
			catch (Exception ex)
			{
				return HandleStandardError(ex, $"Set cover image for property {propertyId}");
			}
		}
	}

	/// <summary>
	/// DTO for updating image metadata
	/// </summary>
	public class UpdateImageRequest
	{
		public bool? IsCover { get; set; }
		public string? Description { get; set; }
	}
}
