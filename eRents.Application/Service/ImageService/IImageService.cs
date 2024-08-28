using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;

namespace eRents.Application.Service.ImageService
{
	public interface IImageService
	{
		Task<ImageResponse> UploadImageAsync(ImageUploadRequest request);
		Task<IEnumerable<ImageResponse>> GetImagesByPropertyIdAsync(int propertyId);
		Task<ImageResponse> GetImageByIdAsync(int id);
	}
}
