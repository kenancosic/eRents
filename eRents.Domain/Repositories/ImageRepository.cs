using eRents.Domain.Models;
using eRents.Domain.Shared;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace eRents.Domain.Repositories
{
	public class ImageRepository : ConcurrentBaseRepository<Image>, IImageRepository
	{
		public ImageRepository(ERentsContext context, ILogger<ImageRepository> logger) : base(context, logger) { }

		// Basic CRUD operations
		public async Task<Image> GetImageByIdAsync(int id)
		{
			return await _context.Images
				.FirstOrDefaultAsync(i => i.ImageId == id);
		}

		public async Task<IEnumerable<Image>> GetImagesByIdsAsync(IEnumerable<int> imageIds)
		{
			return await _context.Images
				.Where(i => imageIds.Contains(i.ImageId))
				.ToListAsync();
		}

		// Property-specific image operations
		public async Task<IEnumerable<Image>> GetImagesByPropertyIdAsync(int propertyId)
		{
			return await _context.Images
				.Where(i => i.PropertyId == propertyId)
				.OrderByDescending(i => i.IsCover)
				.ThenBy(i => i.DateUploaded)
				.ToListAsync();
		}

		public async Task AssociateImagesWithPropertyAsync(IEnumerable<int> imageIds, int propertyId)
		{
			var images = await _context.Images
				.Where(i => imageIds.Contains(i.ImageId) && (i.PropertyId == null || i.PropertyId != propertyId))
				.ToListAsync();

			foreach (var image in images)
			{
				// Clear other associations when associating with property
				image.PropertyId = propertyId;
				image.ReviewId = null;
				image.MaintenanceIssueId = null;
			}
			// Unit of Work will handle SaveChanges
		}

		public async Task DisassociateImagesFromPropertyAsync(IEnumerable<int> imageIds)
		{
			var images = await _context.Images
				.Where(i => imageIds.Contains(i.ImageId) && i.PropertyId.HasValue)
				.ToListAsync();

			foreach (var image in images)
			{
				image.PropertyId = null;
				image.IsCover = false; // Remove cover status when disassociating
			}
			// Unit of Work will handle SaveChanges
		}

		public async Task<Image?> GetPropertyCoverImageAsync(int propertyId)
		{
			return await _context.Images
				.Where(i => i.PropertyId == propertyId && i.IsCover)
				.FirstOrDefaultAsync();
		}

		public async Task SetPropertyCoverImageAsync(int propertyId, int imageId)
		{
			// First, unset all cover images for this property
			await UnsetAllPropertyCoverImagesAsync(propertyId);
			
			// Then set the specified image as cover
			var image = await _context.Images
				.FirstOrDefaultAsync(i => i.ImageId == imageId && i.PropertyId == propertyId);
			
			if (image != null)
			{
				image.IsCover = true;
			}
		}

		public async Task UnsetAllPropertyCoverImagesAsync(int propertyId)
		{
			var coverImages = await _context.Images
				.Where(i => i.PropertyId == propertyId && i.IsCover)
				.ToListAsync();

			foreach (var image in coverImages)
			{
				image.IsCover = false;
			}
		}

		// Review-specific image operations
		public async Task<IEnumerable<Image>> GetImagesByReviewIdAsync(int reviewId)
		{
			return await _context.Images
				.Where(i => i.ReviewId == reviewId)
				.OrderBy(i => i.DateUploaded)
				.ToListAsync();
		}

		public async Task AssociateImagesWithReviewAsync(IEnumerable<int> imageIds, int reviewId)
		{
			var images = await _context.Images
				.Where(i => imageIds.Contains(i.ImageId) && (i.ReviewId == null || i.ReviewId != reviewId))
				.ToListAsync();

			foreach (var image in images)
			{
				// Clear other associations when associating with review
				image.ReviewId = reviewId;
				image.PropertyId = null;
				image.MaintenanceIssueId = null;
				image.IsCover = false; // Reviews don't use cover concept
			}
			// Unit of Work will handle SaveChanges
		}

		public async Task DisassociateImagesFromReviewAsync(IEnumerable<int> imageIds)
		{
			var images = await _context.Images
				.Where(i => imageIds.Contains(i.ImageId) && i.ReviewId.HasValue)
				.ToListAsync();

			foreach (var image in images)
			{
				image.ReviewId = null;
			}
			// Unit of Work will handle SaveChanges
		}

		public async Task<int> GetReviewImageCountAsync(int reviewId)
		{
			return await _context.Images
				.CountAsync(i => i.ReviewId == reviewId);
		}

		// Maintenance issue-specific image operations
		public async Task<IEnumerable<Image>> GetImagesByMaintenanceIssueIdAsync(int maintenanceIssueId)
		{
			return await _context.Images
				.Where(i => i.MaintenanceIssueId == maintenanceIssueId)
				.OrderBy(i => i.DateUploaded)
				.ToListAsync();
		}

		public async Task AssociateImagesWithMaintenanceIssueAsync(IEnumerable<int> imageIds, int maintenanceIssueId)
		{
			var images = await _context.Images
				.Where(i => imageIds.Contains(i.ImageId) && (i.MaintenanceIssueId == null || i.MaintenanceIssueId != maintenanceIssueId))
				.ToListAsync();

			foreach (var image in images)
			{
				// Clear other associations when associating with maintenance issue
				image.MaintenanceIssueId = maintenanceIssueId;
				image.PropertyId = null;
				image.ReviewId = null;
				image.IsCover = false; // Maintenance issues don't use cover concept
			}
			// Unit of Work will handle SaveChanges
		}

		public async Task DisassociateImagesFromMaintenanceIssueAsync(IEnumerable<int> imageIds)
		{
			var images = await _context.Images
				.Where(i => imageIds.Contains(i.ImageId) && i.MaintenanceIssueId.HasValue)
				.ToListAsync();

			foreach (var image in images)
			{
				image.MaintenanceIssueId = null;
			}
			// Unit of Work will handle SaveChanges
		}

		public async Task<int> GetMaintenanceIssueImageCountAsync(int maintenanceIssueId)
		{
			return await _context.Images
				.CountAsync(i => i.MaintenanceIssueId == maintenanceIssueId);
		}

		// Bulk operations for performance
		public async Task<bool> DeleteImagesByPropertyIdAsync(int propertyId)
		{
			var images = await _context.Images
				.Where(i => i.PropertyId == propertyId)
				.ToListAsync();

			if (images.Any())
			{
				_context.Images.RemoveRange(images);
				return true;
			}
			return false;
		}

		public async Task<bool> DeleteImagesByReviewIdAsync(int reviewId)
		{
			var images = await _context.Images
				.Where(i => i.ReviewId == reviewId)
				.ToListAsync();

			if (images.Any())
			{
				_context.Images.RemoveRange(images);
				return true;
			}
			return false;
		}

		public async Task<bool> DeleteImagesByMaintenanceIssueIdAsync(int maintenanceIssueId)
		{
			var images = await _context.Images
				.Where(i => i.MaintenanceIssueId == maintenanceIssueId)
				.ToListAsync();

			if (images.Any())
			{
				_context.Images.RemoveRange(images);
				return true;
			}
			return false;
		}

		// Utility methods
		public async Task<bool> IsImageAssociatedWithPropertyAsync(int imageId, int propertyId)
		{
			return await _context.Images
				.AnyAsync(i => i.ImageId == imageId && i.PropertyId == propertyId);
		}

		public async Task<bool> IsImageAssociatedWithReviewAsync(int imageId, int reviewId)
		{
			return await _context.Images
				.AnyAsync(i => i.ImageId == imageId && i.ReviewId == reviewId);
		}

		public async Task<bool> IsImageAssociatedWithMaintenanceIssueAsync(int imageId, int maintenanceIssueId)
		{
			return await _context.Images
				.AnyAsync(i => i.ImageId == imageId && i.MaintenanceIssueId == maintenanceIssueId);
		}

		public async Task<string?> GetImageAssociationTypeAsync(int imageId)
		{
			var image = await _context.Images
				.Select(i => new { 
					i.ImageId, 
					i.PropertyId, 
					i.ReviewId, 
					i.MaintenanceIssueId 
				})
				.FirstOrDefaultAsync(i => i.ImageId == imageId);

			if (image == null) return null;

			if (image.PropertyId.HasValue) return "Property";
			if (image.ReviewId.HasValue) return "Review";
			if (image.MaintenanceIssueId.HasValue) return "MaintenanceIssue";
			
			return null; // Orphaned image
		}

		// Optimization methods
		public async Task<IEnumerable<Image>> GetImagesWithMetadataOnlyAsync(IEnumerable<int> imageIds)
		{
			return await _context.Images
				.Where(i => imageIds.Contains(i.ImageId))
				.Select(i => new Image
				{
					ImageId = i.ImageId,
					PropertyId = i.PropertyId,
					ReviewId = i.ReviewId,
					MaintenanceIssueId = i.MaintenanceIssueId,
					FileName = i.FileName,
					ContentType = i.ContentType,
					Width = i.Width,
					Height = i.Height,
					FileSizeBytes = i.FileSizeBytes,
					DateUploaded = i.DateUploaded,
					IsCover = i.IsCover,
					CreatedAt = i.CreatedAt,
					UpdatedAt = i.UpdatedAt,
					CreatedBy = i.CreatedBy,
					ModifiedBy = i.ModifiedBy
					// Explicitly exclude ImageData and ThumbnailData for performance
				})
				.ToListAsync();
		}

		public async Task<IEnumerable<Image>> GetThumbnailOnlyImagesAsync(IEnumerable<int> imageIds)
		{
			return await _context.Images
				.Where(i => imageIds.Contains(i.ImageId))
				.Select(i => new Image
				{
					ImageId = i.ImageId,
					PropertyId = i.PropertyId,
					ReviewId = i.ReviewId,
					MaintenanceIssueId = i.MaintenanceIssueId,
					FileName = i.FileName,
					ContentType = i.ContentType,
					Width = i.Width,
					Height = i.Height,
					DateUploaded = i.DateUploaded,
					IsCover = i.IsCover,
					ThumbnailData = i.ThumbnailData // Include only thumbnail, not full ImageData
				})
				.ToListAsync();
		}

		/// <summary>
		/// Save changes directly to database - used for immediate operations like image upload
		/// that require the database-generated ID immediately
		/// </summary>
		public async Task SaveChangesDirectAsync()
		{
			await _context.SaveChangesAsync();
		}
	}
}
