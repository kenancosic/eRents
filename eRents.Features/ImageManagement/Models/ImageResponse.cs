using System;

namespace eRents.Features.ImageManagement.Models;

public class ImageResponse
{
    public int ImageId { get; set; }

    public int? PropertyId { get; set; }
    public int? MaintenanceIssueId { get; set; }

    public string? FileName { get; set; }
    public string? ContentType { get; set; }
    public bool IsCover { get; set; }

    public int? Width { get; set; }
    public int? Height { get; set; }
    // Note: File size and upload date are intentionally not exposed.
    // Size remains an internal optimization detail; audit fields cover timing.

    // Include binary payloads so existing endpoints can return image bytes
    public byte[]? ImageData { get; set; }

    // Audit fields surfaced via BaseEntity on Domain
    public DateTime CreatedAt { get; set; }
    public string CreatedBy { get; set; } = string.Empty;
    public DateTime UpdatedAt { get; set; }
    public string? UpdatedBy { get; set; }
}