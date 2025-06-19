using eRents.Domain.Models;
using eRents.Domain.Shared;

namespace eRents.Domain.Repositories
{
	public interface IImageRepository : IBaseRepository<Image>
	{
		// Basic CRUD operations
		Task<Image> GetImageByIdAsync(int id);
		Task<IEnumerable<Image>> GetImagesByIdsAsync(IEnumerable<int> imageIds);
		
		// Property-specific image operations
		Task<IEnumerable<Image>> GetImagesByPropertyIdAsync(int propertyId);
		Task AssociateImagesWithPropertyAsync(IEnumerable<int> imageIds, int propertyId);
		Task DisassociateImagesFromPropertyAsync(IEnumerable<int> imageIds);
		Task<Image?> GetPropertyCoverImageAsync(int propertyId);
		Task SetPropertyCoverImageAsync(int propertyId, int imageId);
		Task UnsetAllPropertyCoverImagesAsync(int propertyId);
		
		// Review-specific image operations
		Task<IEnumerable<Image>> GetImagesByReviewIdAsync(int reviewId);
		Task AssociateImagesWithReviewAsync(IEnumerable<int> imageIds, int reviewId);
		Task DisassociateImagesFromReviewAsync(IEnumerable<int> imageIds);
		Task<int> GetReviewImageCountAsync(int reviewId);
		
		// Maintenance issue-specific image operations
		Task<IEnumerable<Image>> GetImagesByMaintenanceIssueIdAsync(int maintenanceIssueId);
		Task AssociateImagesWithMaintenanceIssueAsync(IEnumerable<int> imageIds, int maintenanceIssueId);
		Task DisassociateImagesFromMaintenanceIssueAsync(IEnumerable<int> imageIds);
		Task<int> GetMaintenanceIssueImageCountAsync(int maintenanceIssueId);
		
		// Bulk operations for performance
		Task<bool> DeleteImagesByPropertyIdAsync(int propertyId);
		Task<bool> DeleteImagesByReviewIdAsync(int reviewId);
		Task<bool> DeleteImagesByMaintenanceIssueIdAsync(int maintenanceIssueId);
		
		// Utility methods
		Task<bool> IsImageAssociatedWithPropertyAsync(int imageId, int propertyId);
		Task<bool> IsImageAssociatedWithReviewAsync(int imageId, int reviewId);
		Task<bool> IsImageAssociatedWithMaintenanceIssueAsync(int imageId, int maintenanceIssueId);
		Task<string?> GetImageAssociationTypeAsync(int imageId); // Returns "Property", "Review", "MaintenanceIssue", or null
		
		// Optimization methods
		Task<IEnumerable<Image>> GetImagesWithMetadataOnlyAsync(IEnumerable<int> imageIds); // Excludes binary data for performance
		Task<IEnumerable<Image>> GetThumbnailOnlyImagesAsync(IEnumerable<int> imageIds); // Returns only thumbnail data
		
		// Direct save method for immediate operations
		Task SaveChangesDirectAsync(); // Save changes directly to database when DB-generated ID is needed immediately
	}
}
