using System;
using System.Collections.Generic;

namespace eRents.Domain.Entities;

public partial class Image
{
	public int ImageId { get; set; }

	public int? ReviewId { get; set; }

	public int? PropertyId { get; set; }

	public string? FileName { get; set; }

	public byte[] ImageData { get; set; } = null!;

	public DateTime? DateUploaded { get; set; }

	public virtual Property? Property { get; set; }

	public virtual Review? Review { get; set; }
}
