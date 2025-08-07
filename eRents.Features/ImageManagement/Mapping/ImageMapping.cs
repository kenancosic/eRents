using System;
using Mapster;
using eRents.Domain.Models;
using eRents.Features.ImageManagement.Models;

namespace eRents.Features.ImageManagement.Mapping;

public static class ImageMapping
{
    public static void Configure(TypeAdapterConfig config)
    {
        // Entity -> Response (projection-safe, metadata only; exclude large payloads)
        config.NewConfig<Image, ImageResponse>()
            .Map(d => d.ImageId, s => s.ImageId)
            .Map(d => d.ReviewId, s => s.ReviewId)
            .Map(d => d.PropertyId, s => s.PropertyId)
            .Map(d => d.MaintenanceIssueId, s => s.MaintenanceIssueId)
            .Map(d => d.FileName, s => s.FileName)
            .Map(d => d.ContentType, s => s.ContentType)
            .Map(d => d.IsCover, s => s.IsCover)
            .Map(d => d.Width, s => s.Width)
            .Map(d => d.Height, s => s.Height)
            .Map(d => d.FileSizeBytes, s => s.FileSizeBytes)
            .Map(d => d.DateUploaded, s => s.DateUploaded)
            // audit (from BaseEntity)
            .Map(d => d.CreatedAt, s => s.CreatedAt)
            .Map(d => d.CreatedBy, s => s.CreatedBy)
            .Map(d => d.UpdatedAt, s => s.UpdatedAt);

        // Request -> Entity (ignore identity/audit; AfterMapping computes deriveds if needed)
        config.NewConfig<ImageRequest, Image>()
            .Ignore(d => d.ImageId)
            .Ignore(d => d.CreatedAt)
            .Ignore(d => d.CreatedBy)
            .Ignore(d => d.UpdatedAt)
            .Map(d => d.ReviewId, s => s.ReviewId)
            .Map(d => d.PropertyId, s => s.PropertyId)
            .Map(d => d.MaintenanceIssueId, s => s.MaintenanceIssueId)
            .Map(d => d.FileName, s => s.FileName)
            .Map(d => d.ContentType, s => s.ContentType)
            .Map(d => d.ImageData, s => s.ImageData)
            .Map(d => d.ThumbnailData, s => s.ThumbnailData)
            .Map(d => d.IsCover, s => s.IsCover)
            .Map(d => d.Width, s => s.Width)
            .Map(d => d.Height, s => s.Height)
            .Map(d => d.FileSizeBytes, s => s.FileSizeBytes)
            .Map(d => d.DateUploaded, s => s.DateUploaded)
            .AfterMapping((src, dest) =>
            {
                // Normalize DateUploaded if not provided
                if (dest.DateUploaded == null)
                    dest.DateUploaded = DateTime.UtcNow;

                // Derive FileSizeBytes if not provided and data present
                if (!dest.FileSizeBytes.HasValue && dest.ImageData != null)
                    dest.FileSizeBytes = dest.ImageData.LongLength;
            });
    }
}