using AutoMapper;
using eRents.Domain.Models;
using eRents.Domain.Repositories;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;

namespace eRents.Application.Service.ImageService
{
	public class ImageService : IImageService
	{
		private readonly IImageRepository _imageRepository;
		private readonly IMapper _mapper;

		public ImageService(IImageRepository imageRepository, IMapper mapper)
		{
			_imageRepository = imageRepository;
			_mapper = mapper;
		}

		public async Task<ImageResponse> UploadImageAsync(ImageUploadRequest request)
		{
			using var memoryStream = new MemoryStream();
			await request.ImageFile.CopyToAsync(memoryStream);
			var imageData = memoryStream.ToArray();

			var image = new Image
			{
				FileName = request.ImageFile.FileName,
				ImageData = imageData,
				PropertyId = request.PropertyId,
				ReviewId = request.ReviewId,
				MaintenanceIssueId = request.MaintenanceIssueId,
				ContentType = request.ImageFile.ContentType,
				FileSizeBytes = request.ImageFile.Length,
				DateUploaded = DateTime.UtcNow,
				IsCover = request.IsCover ?? false
			};

			// Generate thumbnail if it's an image
			if (request.ImageFile.ContentType?.StartsWith("image/") == true)
			{
				image.ThumbnailData = GenerateThumbnail(imageData);
			}

			await _imageRepository.AddAsync(image);

			// Use AutoMapper but include the binary data for response
			var response = _mapper.Map<ImageResponse>(image);
			response.ImageData = image.ImageData;
			response.ThumbnailData = image.ThumbnailData;
			
			return response;
		}

		public async Task<IEnumerable<ImageResponse>> GetImagesByPropertyIdAsync(int propertyId)
		{
			var images = await _imageRepository.GetImagesByPropertyIdAsync(propertyId);
			return _mapper.Map<IEnumerable<ImageResponse>>(images);
		}

		public async Task<ImageResponse> GetImageByIdAsync(int id)
		{
			var image = await _imageRepository.GetImageByIdAsync(id);
			if (image == null) return null;

			// Use AutoMapper but include the binary data for response
			var response = _mapper.Map<ImageResponse>(image);
			response.ImageData = image.ImageData;
			response.ThumbnailData = image.ThumbnailData;
			
			return response;
		}

		private byte[] GenerateThumbnail(byte[] imageData)
		{
			// Simple thumbnail generation - in production, use a proper image processing library
			// For now, return the original image data (you can implement proper thumbnail generation later)
			// TODO: Implement proper thumbnail generation using ImageSharp or similar
			return imageData;
		}
	}
}

