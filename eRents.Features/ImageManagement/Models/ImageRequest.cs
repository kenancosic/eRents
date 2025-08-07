using System;

namespace eRents.Features.ImageManagement.Models;

public class ImageRequest
{
    public int? ReviewId { get; set; }
    public int? PropertyId { get; set; }
    public int? MaintenanceIssueId { get; set; }

    public string FileName { get; set; } = string.Empty;
    public string ContentType { get; set; } = string.Empty;

    // Note: Kept as byte[] to match Domain. Large payload handling can be addressed at transport layer.
    public byte[] ImageData { get; set; } = Array.Empty<byte>();
    public byte[]? ThumbnailData { get; set; }

    public bool IsCover { get; set; }

    public int? Width { get; set; }
    public int? Height { get; set; }
    public long? FileSizeBytes { get; set; }

    public DateTime? DateUploaded { get; set; }
}