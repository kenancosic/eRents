using Microsoft.AspNetCore.Mvc;
using eRents.Domain.Repositories;

namespace eRents.WebApi.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class ImagesController : ControllerBase
    {
        private readonly IImageRepository _imageRepository;

        public ImagesController(IImageRepository imageRepository)
        {
            _imageRepository = imageRepository;
        }

        /// <summary>
        /// Get image by ID and serve as binary data
        /// </summary>
        /// <param name="imageId">ID of the image</param>
        /// <returns>Binary image data with appropriate content type</returns>
        [HttpGet("{imageId}")]
        public async Task<IActionResult> GetImage(int imageId)
        {
            try
            {
                var image = await _imageRepository.GetByIdAsync(imageId);
                if (image == null)
                    return NotFound("Image not found");

                if (image.ImageData == null || image.ImageData.Length == 0)
                    return NotFound("Image data not available");

                var contentType = image.ContentType ?? "image/jpeg"; // Default to JPEG if not specified
                
                return File(image.ImageData, contentType, image.FileName ?? $"image_{imageId}");
            }
            catch (Exception ex)
            {
                return BadRequest($"Error retrieving image: {ex.Message}");
            }
        }

        /// <summary>
        /// Get thumbnail version of image by ID
        /// </summary>
        /// <param name="imageId">ID of the image</param>
        /// <returns>Binary thumbnail data with appropriate content type</returns>
        [HttpGet("{imageId}/thumbnail")]
        public async Task<IActionResult> GetThumbnail(int imageId)
        {
            try
            {
                var image = await _imageRepository.GetByIdAsync(imageId);
                if (image == null)
                    return NotFound("Image not found");

                // Check if thumbnail data exists
                if (image.ThumbnailData == null || image.ThumbnailData.Length == 0)
                {
                    // If no thumbnail, fall back to original image
                    if (image.ImageData == null || image.ImageData.Length == 0)
                        return NotFound("Image data not available");
                    
                    var contentType = image.ContentType ?? "image/jpeg";
                    return File(image.ImageData, contentType, image.FileName ?? $"image_{imageId}");
                }

                var thumbnailContentType = image.ContentType ?? "image/jpeg";
                return File(image.ThumbnailData, thumbnailContentType, $"thumb_{image.FileName ?? $"image_{imageId}"}");
            }
            catch (Exception ex)
            {
                return BadRequest($"Error retrieving thumbnail: {ex.Message}");
            }
        }

        /// <summary>
        /// Get image metadata without binary data
        /// </summary>
        /// <param name="imageId">ID of the image</param>
        /// <returns>Image metadata</returns>
        [HttpGet("{imageId}/info")]
        public async Task<IActionResult> GetImageInfo(int imageId)
        {
            try
            {
                var image = await _imageRepository.GetByIdAsync(imageId);
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
                    HasThumbnail = image.ThumbnailData != null && image.ThumbnailData.Length > 0
                };

                return Ok(imageInfo);
            }
            catch (Exception ex)
            {
                return BadRequest($"Error retrieving image info: {ex.Message}");
            }
        }
    }
} 