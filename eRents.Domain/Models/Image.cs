using System;
using System.Collections.Generic;

namespace eRents.Domain.Models;

public partial class Image
{
    public int ImageId { get; set; }

    public int? ReviewId { get; set; }

    public int? PropertyId { get; set; }

    public int? MaintenanceIssueId { get; set; }

    public byte[] ImageData { get; set; } = null!;

    public DateTime? DateUploaded { get; set; }

    public string? FileName { get; set; }
    
    public bool IsCover { get; set; }

    // Additional fields for frontend unification
    public string? ContentType { get; set; }  // e.g., "image/jpeg", "image/png"
    
    public int? Width { get; set; }           // Image dimensions for UI layout
    
    public int? Height { get; set; }
    
    public long? FileSizeBytes { get; set; }  // File size for optimization
    
    public byte[]? ThumbnailData { get; set; } // Thumbnail for mobile optimization

    public virtual Property? Property { get; set; }

    public virtual Review? Review { get; set; }

    public virtual MaintenanceIssue? MaintenanceIssue { get; set; }
}
