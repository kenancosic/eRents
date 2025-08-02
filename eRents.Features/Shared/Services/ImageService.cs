/*
 * SIMPLIFIED FOR ACADEMIC PURPOSES
 *
 * Original ImageService.cs removed as part of Phase 7B: Enterprise Feature Removal
 *
 * The original service contained 503 lines of complex enterprise image management functionality including:
 * - Thumbnail generation with complex image processing
 * - Bulk operations for property image updates
 * - Specialized image queries for maintenance and review images
 * - Complex cover image management with automatic unset logic
 * - Advanced authorization helpers with multi-type image access control
 * - Complex metadata updates with business logic
 * - Enterprise-level bulk processing operations
 *
 * Replaced with simplified version focusing on basic upload/display functionality
 * for academic thesis requirements.
 *
 * Removed: January 30, 2025
 * Reason: Simplify image management to basic upload/display per Phase 7B requirements
 */

using eRents.Domain.Models;
using eRents.Domain.Shared;
using eRents.Features.Shared.DTOs;
using eRents.Domain.Shared.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace eRents.Features.Shared.Services
{
    /// <summary>
    /// Simplified image management service for academic thesis requirements
    /// Focuses on basic upload, display, and delete functionality for property images only
    /// </summary>
    public class ImageService : IImageService
    {
        private readonly ERentsContext _context;
        private readonly IUnitOfWork _unitOfWork;
        private readonly ICurrentUserService _currentUserService;
        private readonly ILogger<ImageService> _logger;

        public ImageService(
            ERentsContext context,
            IUnitOfWork unitOfWork,
            ICurrentUserService currentUserService,
            ILogger<ImageService> logger)
        {
            _context = context;
            _unitOfWork = unitOfWork;
            _currentUserService = currentUserService;
            _logger = logger;
        }

        #region Basic Image Operations

        /// <summary>
        /// Upload a basic property image (simplified - no thumbnails)
        /// </summary>
        public async Task<ImageResponse> UploadImageAsync(ImageUploadRequest request)
        {
            try
            {
                var currentUserId = _currentUserService.GetUserIdAsInt();

                // Basic ownership verification
                var isOwner = await _context.Properties
                    .AnyAsync(p => p.PropertyId == request.PropertyId && p.OwnerId == currentUserId);
                
                if (!isOwner)
                    throw new UnauthorizedAccessException("You can only upload images for your own properties");

                using var memoryStream = new MemoryStream();
                await request.ImageFile.CopyToAsync(memoryStream);
                var imageData = memoryStream.ToArray();

                var image = new Image
                {
                    FileName = request.ImageFile.FileName,
                    ImageData = imageData,
                    PropertyId = request.PropertyId,
                    ContentType = request.ImageFile.ContentType,
                    FileSizeBytes = request.ImageFile.Length,
                    DateUploaded = DateTime.UtcNow,
                    IsCover = false, // Simplified: no cover image logic
                    CreatedBy = currentUserId,
                    ModifiedBy = currentUserId,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };

                _context.Images.Add(image);
                await _unitOfWork.SaveChangesAsync();

                _logger.LogInformation("Image uploaded for property {PropertyId}", request.PropertyId);
                return ToImageResponse(image);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error uploading image");
                throw;
            }
        }

        /// <summary>
        /// Get all images for a property (basic display)
        /// </summary>
        public async Task<IEnumerable<ImageResponse>> GetImagesByPropertyIdAsync(int propertyId)
        {
            try
            {
                var images = await _context.Images
                    .Where(i => i.PropertyId == propertyId)
                    .OrderBy(i => i.DateUploaded)
                    .AsNoTracking()
                    .ToListAsync();

                return images.Select(ToImageResponse);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving images for property {PropertyId}", propertyId);
                throw;
            }
        }

        /// <summary>
        /// Get a single image by ID (basic retrieval)
        /// </summary>
        public async Task<ImageResponse?> GetImageByIdAsync(int id)
        {
            try
            {
                var image = await _context.Images
                    .FirstOrDefaultAsync(i => i.ImageId == id);

                return image != null ? ToImageResponse(image) : null;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving image {ImageId}", id);
                throw;
            }
        }

        /// <summary>
        /// Delete an image (basic deletion with ownership check)
        /// </summary>
        public async Task<bool> DeleteImageAsync(int imageId)
        {
            try
            {
                var currentUserId = _currentUserService.GetUserIdAsInt();

                var image = await _context.Images
                    .Include(i => i.Property)
                    .FirstOrDefaultAsync(i => i.ImageId == imageId);

                if (image == null)
                    return false;

                // Basic ownership verification
                if (image.Property?.OwnerId != currentUserId)
                    throw new UnauthorizedAccessException("You can only delete images for your own properties");

                _context.Images.Remove(image);
                await _unitOfWork.SaveChangesAsync();

                _logger.LogInformation("Image deleted: {ImageId}", imageId);
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting image {ImageId}", imageId);
                throw;
            }
        }

        #endregion

        #region Specialized Image Queries

        /// <summary>
        /// Get images associated with maintenance issue
        /// </summary>
        public async Task<IEnumerable<ImageResponse>> GetImagesByMaintenanceIssueIdAsync(int maintenanceIssueId)
        {
            try
            {
                var images = await _context.Images
                    .Where(i => i.MaintenanceIssueId == maintenanceIssueId)
                    .OrderBy(i => i.DateUploaded)
                    .AsNoTracking()
                    .ToListAsync();

                return images.Select(ToImageResponse);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving images for maintenance issue {MaintenanceIssueId}", maintenanceIssueId);
                throw;
            }
        }

        /// <summary>
        /// Get images associated with review
        /// </summary>
        public async Task<IEnumerable<ImageResponse>> GetImagesByReviewIdAsync(int reviewId)
        {
            try
            {
                var images = await _context.Images
                    .Where(i => i.ReviewId == reviewId)
                    .OrderBy(i => i.DateUploaded)
                    .AsNoTracking()
                    .ToListAsync();

                return images.Select(ToImageResponse);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving images for review {ReviewId}", reviewId);
                throw;
            }
        }

        /// <summary>
        /// Set specific image as cover image for property
        /// </summary>
        public async Task<bool> SetCoverImageAsync(int propertyId, int imageId)
        {
            try
            {
                var currentUserId = _currentUserService.GetUserIdAsInt();

                // Verify ownership
                var isOwner = await _context.Properties
                    .AnyAsync(p => p.PropertyId == propertyId && p.OwnerId == currentUserId);
                
                if (!isOwner)
                    throw new UnauthorizedAccessException("You can only set cover images for your own properties");

                // Unset current cover image
                await _context.Images
                    .Where(i => i.PropertyId == propertyId && i.IsCover)
                    .ExecuteUpdateAsync(i => i.SetProperty(img => img.IsCover, false));

                // Set new cover image
                var updatedRows = await _context.Images
                    .Where(i => i.ImageId == imageId && i.PropertyId == propertyId)
                    .ExecuteUpdateAsync(i => i.SetProperty(img => img.IsCover, true));

                await _unitOfWork.SaveChangesAsync();
                
                _logger.LogInformation("Cover image set for property {PropertyId}: image {ImageId}", propertyId, imageId);
                return updatedRows > 0;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error setting cover image for property {PropertyId}", propertyId);
                throw;
            }
        }

        /// <summary>
        /// Update image metadata (cover status)
        /// </summary>
        public async Task<ImageResponse> UpdateImageMetadataAsync(int imageId, bool? isCover = null)
        {
            try
            {
                var currentUserId = _currentUserService.GetUserIdAsInt();

                var image = await _context.Images
                    .Include(i => i.Property)
                    .FirstOrDefaultAsync(i => i.ImageId == imageId);

                if (image == null)
                    throw new ArgumentException($"Image {imageId} not found");

                // Verify ownership
                if (image.Property?.OwnerId != currentUserId)
                    throw new UnauthorizedAccessException("You can only update images for your own properties");

                if (isCover.HasValue)
                {
                    image.IsCover = isCover.Value;
                    image.UpdatedAt = DateTime.UtcNow;
                    image.ModifiedBy = currentUserId;
                }

                await _unitOfWork.SaveChangesAsync();
                
                _logger.LogInformation("Image metadata updated: {ImageId}", imageId);
                return ToImageResponse(image);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating image metadata {ImageId}", imageId);
                throw;
            }
        }

        #endregion

        #region Bulk Operations

        /// <summary>
        /// Delete all images for a property
        /// </summary>
        public async Task<bool> DeleteImagesByPropertyIdAsync(int propertyId)
        {
            try
            {
                var currentUserId = _currentUserService.GetUserIdAsInt();

                // Verify ownership
                var isOwner = await _context.Properties
                    .AnyAsync(p => p.PropertyId == propertyId && p.OwnerId == currentUserId);
                
                if (!isOwner)
                    throw new UnauthorizedAccessException("You can only delete images for your own properties");

                var deletedCount = await _context.Images
                    .Where(i => i.PropertyId == propertyId)
                    .ExecuteDeleteAsync();

                await _unitOfWork.SaveChangesAsync();
                
                _logger.LogInformation("Deleted {Count} images for property {PropertyId}", deletedCount, propertyId);
                return deletedCount > 0;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting images for property {PropertyId}", propertyId);
                throw;
            }
        }

        /// <summary>
        /// Process property image updates (add/remove/update multiple images)
        /// </summary>
        public async Task ProcessPropertyImageUpdateAsync(
            int propertyId,
            List<int>? existingImageIds,
            List<Microsoft.AspNetCore.Http.IFormFile>? newImages,
            List<string>? imageFileNames,
            List<bool>? imageIsCoverFlags)
        {
            try
            {
                var currentUserId = _currentUserService.GetUserIdAsInt();

                // Verify ownership
                var isOwner = await _context.Properties
                    .AnyAsync(p => p.PropertyId == propertyId && p.OwnerId == currentUserId);
                
                if (!isOwner)
                    throw new UnauthorizedAccessException("You can only update images for your own properties");

                // Handle existing images (keep only specified ones)
                if (existingImageIds?.Any() == true)
                {
                    await _context.Images
                        .Where(i => i.PropertyId == propertyId && !existingImageIds.Contains(i.ImageId))
                        .ExecuteDeleteAsync();
                }
                else
                {
                    // Remove all existing images if no existing IDs specified
                    await _context.Images
                        .Where(i => i.PropertyId == propertyId)
                        .ExecuteDeleteAsync();
                }

                // Add new images
                if (newImages?.Any() == true)
                {
                    for (int i = 0; i < newImages.Count; i++)
                    {
                        var imageFile = newImages[i];
                        var isCover = imageIsCoverFlags?.ElementAtOrDefault(i) ?? false;

                        using var memoryStream = new MemoryStream();
                        await imageFile.CopyToAsync(memoryStream);
                        var imageData = memoryStream.ToArray();

                        var image = new Image
                        {
                            FileName = imageFileNames?.ElementAtOrDefault(i) ?? imageFile.FileName,
                            ImageData = imageData,
                            PropertyId = propertyId,
                            ContentType = imageFile.ContentType,
                            FileSizeBytes = imageFile.Length,
                            DateUploaded = DateTime.UtcNow,
                            IsCover = isCover,
                            CreatedBy = currentUserId,
                            ModifiedBy = currentUserId,
                            CreatedAt = DateTime.UtcNow,
                            UpdatedAt = DateTime.UtcNow
                        };

                        _context.Images.Add(image);
                    }
                }

                await _unitOfWork.SaveChangesAsync();
                
                _logger.LogInformation("Bulk image update completed for property {PropertyId}", propertyId);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error processing bulk image update for property {PropertyId}", propertyId);
                throw;
            }
        }

        #endregion

        #region Authorization Helpers

        /// <summary>
        /// Check if user can access specific image
        /// </summary>
        public async Task<bool> UserCanAccessImageAsync(int imageId, int userId, string userRole)
        {
            try
            {
                var image = await _context.Images
                    .Include(i => i.Property)
                    .Include(i => i.MaintenanceIssue)
                    .Include(i => i.Review)
                    .FirstOrDefaultAsync(i => i.ImageId == imageId);

                if (image == null)
                    return false;

                // Property owners can access their property images
                if (image.Property?.OwnerId == userId)
                    return true;

                // Users can access images for maintenance issues they created
                if (image.MaintenanceIssue?.ReportedByUserId == userId)
                    return true;

                // Users can access images for reviews they wrote
                if (image.Review?.ReviewerId == userId)
                    return true;

                // Admin can access all images
                if (userRole?.Equals("Admin", StringComparison.OrdinalIgnoreCase) == true)
                    return true;

                return false;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error checking image access for user {UserId}", userId);
                return false;
            }
        }

        #endregion

        #region Private Helper Methods

        private ImageResponse ToImageResponse(Image image)
        {
            return new ImageResponse
            {
                ImageId = image.ImageId,
                FileName = image.FileName ?? string.Empty,
                DateUploaded = image.DateUploaded ?? DateTime.UtcNow,
                Url = $"/Image/{image.ImageId}",
                ImageData = image.ImageData,
                ContentType = image.ContentType,
                Width = image.Width,
                Height = image.Height,
                FileSizeBytes = image.FileSizeBytes,
                IsCover = image.IsCover
            };
        }

        #endregion
    }
}