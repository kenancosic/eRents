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
		public byte[] ImageData { get; set; }  // Byte array containing the image data
	}
}
