using eRents.Features.Shared.DTOs;

namespace eRents.Features.Shared.Services
{
    /// <summary>
    /// Image management service for handling property, review, and maintenance images
    /// </summary>
    public interface IImageService
    {
        #region Core Image Operations

        /// <summary>
        /// Upload a new image for property, review, or maintenance issue
        /// </summary>
        Task<ImageResponse> UploadImageAsync(ImageUploadRequest request);

        /// <summary>
        /// Get images by property ID
        /// </summary>
        Task<IEnumerable<ImageResponse>> GetImagesByPropertyIdAsync(int propertyId);

        /// <summary>
        /// Get image by ID with binary data
        /// </summary>
        Task<ImageResponse?> GetImageByIdAsync(int id);

        /// <summary>
        /// Delete image by ID
        /// </summary>
        Task<bool> DeleteImageAsync(int imageId);

        /// <summary>
        /// Update image metadata (cover status)
        /// </summary>
        Task<ImageResponse> UpdateImageMetadataAsync(int imageId, bool? isCover = null);

        #endregion

        #region Specialized Image Queries

        /// <summary>
        /// Get images associated with maintenance issue
        /// </summary>
        Task<IEnumerable<ImageResponse>> GetImagesByMaintenanceIssueIdAsync(int maintenanceIssueId);

        /// <summary>
        /// Get images associated with review
        /// </summary>
        Task<IEnumerable<ImageResponse>> GetImagesByReviewIdAsync(int reviewId);

        /// <summary>
        /// Set specific image as cover image for property
        /// </summary>
        Task<bool> SetCoverImageAsync(int propertyId, int imageId);

        #endregion

        #region Bulk Operations

        /// <summary>
        /// Delete all images for a property
        /// </summary>
        Task<bool> DeleteImagesByPropertyIdAsync(int propertyId);

        /// <summary>
        /// Process property image updates (add/remove/update multiple images)
        /// </summary>
        Task ProcessPropertyImageUpdateAsync(
            int propertyId,
            List<int>? existingImageIds,
            List<Microsoft.AspNetCore.Http.IFormFile>? newImages,
            List<string>? imageFileNames,
            List<bool>? imageIsCoverFlags);

        #endregion

        #region Authorization Helpers

        /// <summary>
        /// Check if user can access specific image
        /// </summary>
        Task<bool> UserCanAccessImageAsync(int imageId, int userId, string userRole);

        #endregion
    }
} 