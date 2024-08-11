using Microsoft.AspNetCore.Http;

namespace eRents.Shared.DTO.Requests
{
	public class ImageUploadRequest
	{
		public int? PropertyId { get; set; }
		public int? ReviewId { get; set; }
		public IFormFile ImageFile { get; set; }  // The image file to upload
	}

}
