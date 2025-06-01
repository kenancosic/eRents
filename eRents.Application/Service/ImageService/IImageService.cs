using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;

namespace eRents.Application.Service.ImageService
{
	public interface IImageService
	{
		Task<ImageResponse> UploadImageAsync(ImageUploadRequest request);
		Task<IEnumerable<ImageResponse>> GetImagesByPropertyIdAsync(int propertyId);
		Task<ImageResponse> GetImageByIdAsync(int id);
		
		// New methods for comprehensive image management
		Task<bool> DeleteImageAsync(int imageId);
		Task<ImageResponse> UpdateImageMetadataAsync(int imageId, bool? isCover = null, string? description = null);
		Task<IEnumerable<ImageResponse>> GetImagesByMaintenanceIssueIdAsync(int maintenanceIssueId);
		Task<IEnumerable<ImageResponse>> GetImagesByReviewIdAsync(int reviewId);
		Task<bool> SetCoverImageAsync(int propertyId, int imageId);
		
		// Utility methods
		Task<bool> UserCanAccessImageAsync(int imageId, string userId, string userRole);
		Task<bool> DeleteImagesByPropertyIdAsync(int propertyId);
	}
}
