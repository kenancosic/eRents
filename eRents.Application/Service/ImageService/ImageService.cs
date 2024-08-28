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
				ReviewId = request.ReviewId
			};

			await _imageRepository.AddAsync(image);

			return new ImageResponse
			{
				ImageId = image.ImageId,
				FileName = image.FileName,
				DateUploaded = image.DateUploaded.Value,
				ImageData = image.ImageData
			};
		}

		public async Task<IEnumerable<ImageResponse>> GetImagesByPropertyIdAsync(int propertyId)
		{
			var images = await _imageRepository.GetImagesByPropertyIdAsync(propertyId);
			return images.Select(i => new ImageResponse
			{
				ImageId = i.ImageId,
				FileName = i.FileName,
				DateUploaded = i.DateUploaded.Value,
				ImageData = i.ImageData
			});
		}

		public async Task<ImageResponse> GetImageByIdAsync(int id)
		{
			var image = await _imageRepository.GetImageByIdAsync(id);
			if (image == null) return null;

			return new ImageResponse
			{
				ImageId = image.ImageId,
				FileName = image.FileName,
				DateUploaded = image.DateUploaded.Value,
				ImageData = image.ImageData
			};
		}
	}
}

