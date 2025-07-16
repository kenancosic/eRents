using eRents.Domain.Models;
using eRents.Domain.Shared;
using eRents.Features.Shared.DTOs;
using eRents.Domain.Shared.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace eRents.Features.Shared.Services
{
    /// <summary>
    /// Image management service using direct ERentsContext access
    /// Handles property, review, and maintenance images with proper authorization
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

        #region Core Image Operations

        public async Task<ImageResponse> UploadImageAsync(ImageUploadRequest request)
        {
            try
            {
                var currentUserId = _currentUserService.GetUserIdAsInt();
                var currentUserRole = _currentUserService.UserRole;

                if (currentUserRole != "Landlord")
                    throw new UnauthorizedAccessException("Only landlords can upload images");

                // Verify property ownership
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
                    IsCover = request.IsCover,
                    CreatedBy = currentUserId,
                    ModifiedBy = currentUserId,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };

                // Generate thumbnail if it's an image
                if (request.ImageFile.ContentType?.StartsWith("image/") == true)
                {
                    image.ThumbnailData = GenerateThumbnail(imageData);
                }

                _context.Images.Add(image);
                await _unitOfWork.SaveChangesAsync();

                _logger.LogInformation("Image uploaded for property {PropertyId}: {FileName}", request.PropertyId, request.ImageFile.FileName);

                return ToImageResponse(image);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error uploading image for property {PropertyId}", request.PropertyId);
                throw;
            }
        }

        public async Task<IEnumerable<ImageResponse>> GetImagesByPropertyIdAsync(int propertyId)
        {
            try
            {
                var images = await _context.Images
                    .Where(i => i.PropertyId == propertyId)
                    .OrderBy(i => i.IsCover)
                    .ThenBy(i => i.DateUploaded)
                    .AsNoTracking()
                    .ToListAsync();

                return images.Select(ToImageResponseWithoutBinaryData);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving images for property {PropertyId}", propertyId);
                throw;
            }
        }

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

        public async Task<bool> DeleteImageAsync(int imageId)
        {
            try
            {
                var currentUserId = _currentUserService.GetUserIdAsInt();
                var currentUserRole = _currentUserService.UserRole;

                if (currentUserRole != "Landlord")
                    throw new UnauthorizedAccessException("Only landlords can delete images");

                var image = await _context.Images
                    .Include(i => i.Property)
                    .FirstOrDefaultAsync(i => i.ImageId == imageId);

                if (image == null)
                    return false;

                // Verify property ownership
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

        public async Task<ImageResponse> UpdateImageMetadataAsync(int imageId, bool? isCover = null)
        {
            try
            {
                var currentUserId = _currentUserService.GetUserIdAsInt();
                var currentUserRole = _currentUserService.UserRole;

                if (currentUserRole != "Landlord")
                    throw new UnauthorizedAccessException("Only landlords can update image metadata");

                var image = await _context.Images
                    .Include(i => i.Property)
                    .FirstOrDefaultAsync(i => i.ImageId == imageId);

                if (image == null)
                    throw new ArgumentException("Image not found");

                // Verify property ownership
                if (image.Property?.OwnerId != currentUserId)
                    throw new UnauthorizedAccessException("You can only update images for your own properties");

                if (isCover.HasValue)
                {
                    // If setting as cover, unset other cover images for this property
                    if (isCover.Value && image.PropertyId.HasValue)
                    {
                        var otherCoverImages = await _context.Images
                            .Where(i => i.PropertyId == image.PropertyId && i.ImageId != imageId && i.IsCover)
                            .ToListAsync();

                        foreach (var otherImage in otherCoverImages)
                        {
                            otherImage.IsCover = false;
                            otherImage.ModifiedBy = currentUserId;
                            otherImage.UpdatedAt = DateTime.UtcNow;
                        }
                    }

                    image.IsCover = isCover.Value;
                }

                image.ModifiedBy = currentUserId;
                image.UpdatedAt = DateTime.UtcNow;

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

        #region Specialized Image Queries

        public async Task<IEnumerable<ImageResponse>> GetImagesByMaintenanceIssueIdAsync(int maintenanceIssueId)
        {
            try
            {
                var images = await _context.Images
                    .Where(i => i.MaintenanceIssueId == maintenanceIssueId)
                    .OrderBy(i => i.DateUploaded)
                    .AsNoTracking()
                    .ToListAsync();

                return images.Select(ToImageResponseWithoutBinaryData);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving images for maintenance issue {MaintenanceIssueId}", maintenanceIssueId);
                throw;
            }
        }

        public async Task<IEnumerable<ImageResponse>> GetImagesByReviewIdAsync(int reviewId)
        {
            try
            {
                var images = await _context.Images
                    .Where(i => i.ReviewId == reviewId)
                    .OrderBy(i => i.DateUploaded)
                    .AsNoTracking()
                    .ToListAsync();

                return images.Select(ToImageResponseWithoutBinaryData);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving images for review {ReviewId}", reviewId);
                throw;
            }
        }

        public async Task<bool> SetCoverImageAsync(int propertyId, int imageId)
        {
            try
            {
                var currentUserId = _currentUserService.GetUserIdAsInt();
                var currentUserRole = _currentUserService.UserRole;

                if (currentUserRole != "Landlord")
                    throw new UnauthorizedAccessException("Only landlords can set cover images");

                // Verify property ownership
                var isOwner = await _context.Properties
                    .AnyAsync(p => p.PropertyId == propertyId && p.OwnerId == currentUserId);
                
                if (!isOwner)
                    throw new UnauthorizedAccessException("You can only set cover images for your own properties");

                // Verify image belongs to property
                var image = await _context.Images
                    .FirstOrDefaultAsync(i => i.ImageId == imageId && i.PropertyId == propertyId);

                if (image == null)
                    return false;

                // Unset other cover images for this property
                var otherCoverImages = await _context.Images
                    .Where(i => i.PropertyId == propertyId && i.ImageId != imageId && i.IsCover)
                    .ToListAsync();

                foreach (var otherImage in otherCoverImages)
                {
                    otherImage.IsCover = false;
                    otherImage.ModifiedBy = currentUserId;
                    otherImage.UpdatedAt = DateTime.UtcNow;
                }

                // Set this image as cover
                image.IsCover = true;
                image.ModifiedBy = currentUserId;
                image.UpdatedAt = DateTime.UtcNow;

                await _unitOfWork.SaveChangesAsync();

                _logger.LogInformation("Cover image set for property {PropertyId}: {ImageId}", propertyId, imageId);
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error setting cover image for property {PropertyId}", propertyId);
                throw;
            }
        }

        #endregion

        #region Bulk Operations

        public async Task<bool> DeleteImagesByPropertyIdAsync(int propertyId)
        {
            var currentUserId = _currentUserService.GetUserIdAsInt();
            var currentUserRole = _currentUserService.UserRole;

            if (currentUserRole != "Landlord")
                throw new UnauthorizedAccessException("Only landlords can delete property images");

            // Verify property ownership
            var isOwner = await _context.Properties
                .AnyAsync(p => p.PropertyId == propertyId && p.OwnerId == currentUserId);
            
            if (!isOwner)
                throw new UnauthorizedAccessException("You can only delete images for your own properties");

            var images = await _context.Images
                .Where(i => i.PropertyId == propertyId)
                .ToListAsync();

            if (!images.Any())
                return false;

            _context.Images.RemoveRange(images);
            await _unitOfWork.SaveChangesAsync();

            _logger.LogInformation("Deleted {Count} images for property {PropertyId}", images.Count, propertyId);
            return true;
        }

        public async Task ProcessPropertyImageUpdateAsync(
            int propertyId,
            List<int>? existingImageIds,
            List<Microsoft.AspNetCore.Http.IFormFile>? newImages,
            List<string>? imageFileNames,
            List<bool>? imageIsCoverFlags)
        {
            var currentUserId = _currentUserService.GetUserIdAsInt();
            var currentUserRole = _currentUserService.UserRole;

            if (currentUserRole != "Landlord")
                throw new UnauthorizedAccessException("Only landlords can update property images");

            // Verify property ownership
            var isOwner = await _context.Properties
                .AnyAsync(p => p.PropertyId == propertyId && p.OwnerId == currentUserId);
            
            if (!isOwner)
                throw new UnauthorizedAccessException("You can only update images for your own properties");

            // Remove images not in the existing list
            if (existingImageIds != null)
            {
                var imagesToDelete = await _context.Images
                    .Where(i => i.PropertyId == propertyId && !existingImageIds.Contains(i.ImageId))
                    .ToListAsync();

                if (imagesToDelete.Any())
                {
                    _context.Images.RemoveRange(imagesToDelete);
                }
            }

            // Add new images
            if (newImages != null && newImages.Any())
            {
                for (int i = 0; i < newImages.Count; i++)
                {
                    var imageFile = newImages[i];
                    var fileName = imageFileNames?.ElementAtOrDefault(i) ?? imageFile.FileName;
                    var isCover = imageIsCoverFlags?.ElementAtOrDefault(i) ?? false;

                    using var memoryStream = new MemoryStream();
                    await imageFile.CopyToAsync(memoryStream);
                    var imageData = memoryStream.ToArray();

                    var image = new Image
                    {
                        FileName = fileName,
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

                    // Generate thumbnail if it's an image
                    if (imageFile.ContentType?.StartsWith("image/") == true)
                    {
                        image.ThumbnailData = GenerateThumbnail(imageData);
                    }

                    _context.Images.Add(image);
                }
            }

            await _unitOfWork.SaveChangesAsync();
            _logger.LogInformation("Property images updated for property {PropertyId}", propertyId);
        }

        #endregion

        #region Authorization Helpers

        public async Task<bool> UserCanAccessImageAsync(int imageId, int userId, string userRole)
        {
            var image = await _context.Images
                .Include(i => i.Property)
                .FirstOrDefaultAsync(i => i.ImageId == imageId);

            if (image == null)
                return false;

            // Property images: landlords can access their own, others can access public properties
            if (image.PropertyId.HasValue)
            {
                if (userRole == "Landlord")
                {
                    return image.Property?.OwnerId == userId;
                }
                // For tenants/users, assume they can view images of available properties
                return true;
            }

            // Review images: can be accessed by anyone (public reviews)
            if (image.ReviewId.HasValue)
                return true;

            // Maintenance images: only landlords and the reporter can access
            if (image.MaintenanceIssueId.HasValue)
            {
                var maintenanceIssue = await _context.MaintenanceIssues
                    .Include(m => m.Property)
                    .FirstOrDefaultAsync(m => m.MaintenanceIssueId == image.MaintenanceIssueId);

                if (maintenanceIssue?.Property?.OwnerId == userId)
                    return true;

                // Check if user reported the issue
                if (maintenanceIssue?.ReportedByUserId == userId)
                    return true;
            }

            return false;
        }

        #endregion

        #region Private Helper Methods

        private ImageResponse ToImageResponse(Image image, bool includeBinaryData = false)
        {
            return new ImageResponse
            {
                ImageId = image.ImageId,
                FileName = image.FileName ?? string.Empty,
                DateUploaded = image.DateUploaded ?? DateTime.UtcNow,
                Url = $"/Image/{image.ImageId}",
                ImageData = includeBinaryData ? image.ImageData : null,
                ThumbnailData = includeBinaryData ? image.ThumbnailData : null,
                ContentType = image.ContentType,
                Width = image.Width,
                Height = image.Height,
                FileSizeBytes = image.FileSizeBytes,
                IsCover = image.IsCover
            };
        }

        private ImageResponse ToImageResponseWithoutBinaryData(Image image)
        {
            return ToImageResponse(image, includeBinaryData: false);
        }

        private byte[] GenerateThumbnail(byte[] imageData)
        {
            // Basic thumbnail generation - in production, use a proper image library like ImageSharp
            // For now, return a placeholder or the original image
            // TODO: Implement proper thumbnail generation with resize functionality
            return imageData; // Placeholder implementation
        }

        #endregion
    }
} 