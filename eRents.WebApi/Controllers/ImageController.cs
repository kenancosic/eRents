using eRents.Application.Service.ImageService;
using eRents.Shared.DTO.Requests;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;

namespace eRents.WebApi.Controllers
{
	[ApiController]
	[Route("[controller]")]
	[Authorize] // Require authentication for all image operations
	public class ImageController : ControllerBase
	{
		private readonly IImageService _imageService;

		public ImageController(IImageService imageService)
		{
			_imageService = imageService;
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
				var response = await _imageService.UploadImageAsync(request);
				return Ok(response);
			}
			catch (UnauthorizedAccessException ex)
			{
				return Forbid(ex.Message);
			}
			catch (Exception ex)
			{
				return BadRequest($"Image upload failed: {ex.Message}");
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
				var images = await _imageService.GetImagesByPropertyIdAsync(propertyId);
				return Ok(images);
			}
			catch (UnauthorizedAccessException ex)
			{
				return Forbid(ex.Message);
			}
			catch (Exception ex)
			{
				return BadRequest($"Error retrieving property images: {ex.Message}");
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
					return NotFound("Image not found");

				if (image.ImageData == null || image.ImageData.Length == 0)
					return NotFound("Image data not available");

				var contentType = image.ContentType ?? "image/jpeg";
				return File(image.ImageData, contentType, image.FileName);
			}
			catch (Exception ex)
			{
				return BadRequest($"Error retrieving image: {ex.Message}");
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
					return NotFound("Image not found");

				// Use thumbnail if available, otherwise fall back to original
				var imageData = image.ThumbnailData ?? image.ImageData;
				if (imageData == null || imageData.Length == 0)
					return NotFound("Image data not available");

				var contentType = image.ContentType ?? "image/jpeg";
				return File(imageData, contentType, $"thumb_{image.FileName}");
			}
			catch (Exception ex)
			{
				return BadRequest($"Error retrieving thumbnail: {ex.Message}");
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
				var image = await _imageService.GetImageByIdAsync(id);
				if (image == null)
					return NotFound("Image not found");

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
				return BadRequest($"Error retrieving image info: {ex.Message}");
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
				var success = await _imageService.DeleteImageAsync(id);
				if (!success)
					return NotFound("Image not found");

				return Ok(new { message = "Image deleted successfully" });
			}
			catch (UnauthorizedAccessException ex)
			{
				return Forbid(ex.Message);
			}
			catch (Exception ex)
			{
				return BadRequest($"Error deleting image: {ex.Message}");
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
				var updatedImage = await _imageService.UpdateImageMetadataAsync(id, request.IsCover, request.Description);
				return Ok(updatedImage);
			}
			catch (KeyNotFoundException ex)
			{
				return NotFound(ex.Message);
			}
			catch (UnauthorizedAccessException ex)
			{
				return Forbid(ex.Message);
			}
			catch (Exception ex)
			{
				return BadRequest($"Error updating image: {ex.Message}");
			}
		}

		/// <summary>
		/// Set an image as the cover image for a property
		/// </summary>
		[HttpPost("property/{propertyId}/cover/{imageId}")]
		[Authorize(Roles = "Landlord")]
		public async Task<IActionResult> SetCoverImage(int propertyId, int imageId)
		{
			try
			{
				var success = await _imageService.SetCoverImageAsync(propertyId, imageId);
				if (!success)
					return BadRequest("Failed to set cover image");

				return Ok(new { message = "Cover image set successfully" });
			}
			catch (UnauthorizedAccessException ex)
			{
				return Forbid(ex.Message);
			}
			catch (Exception ex)
			{
				return BadRequest($"Error setting cover image: {ex.Message}");
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
