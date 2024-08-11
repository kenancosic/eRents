using eRents.Application.Service.ImageService;
using eRents.Shared.DTO.Requests;
using Microsoft.AspNetCore.Mvc;

namespace eRents.WebApi.Controllers
{
	[ApiController]
	[Route("[controller]")]
	public class ImageController : ControllerBase
	{
		private readonly IImageService _imageService;

		public ImageController(IImageService imageService)
		{
			_imageService = imageService;
		}

		[HttpPost("upload")]
		public async Task<IActionResult> UploadImage([FromForm] ImageUploadRequest request)
		{
			var response = await _imageService.UploadImageAsync(request);
			return Ok(response);
		}

		[HttpGet("property/{propertyId}")]
		public async Task<IActionResult> GetImagesByProperty(int propertyId)
		{
			var images = await _imageService.GetImagesByPropertyIdAsync(propertyId);
			return Ok(images);
		}

		[HttpGet("{id}")]
		public async Task<IActionResult> GetImage(int id)
		{
			var image = await _imageService.GetImageByIdAsync(id);
			if (image == null) return NotFound();
			return File(image.ImageData, "image/jpeg", image.FileName);
		}
	}

}
