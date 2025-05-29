using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eRents.Shared.DTO.Response
{
	public class ImageResponse
	{
		public int ImageId { get; set; }
		public string FileName { get; set; }
		public DateTime DateUploaded { get; set; }
		public string Url { get; set; }  // URL to access the image via API endpoint
		public byte[]? ImageData { get; set; }  // Optional: only include when specifically requested
		public string? ContentType { get; set; }  // MIME type (e.g., "image/jpeg")
		public int? Width { get; set; }
		public int? Height { get; set; }
		public long? FileSizeBytes { get; set; }
		public bool IsCover { get; set; }  // Is this the cover/primary image
	}
}
