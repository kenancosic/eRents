using Microsoft.AspNetCore.Http;

namespace eRents.Shared.DTO.Requests
{
	/// <summary>
	/// DTO for uploading an image for a property, review, or maintenance issue.
	/// </summary>
	public class ImageUploadRequest
	{
		public int? PropertyId { get; set; }
		public int? ReviewId { get; set; }
		public int? MaintenanceIssueId { get; set; }
		public IFormFile ImageFile { get; set; }  // The image file to upload
		public bool? IsCover { get; set; }  // Whether this image is the cover/primary image
	}

}
