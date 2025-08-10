using System;
using AutoMapper;
using eRents.Domain.Models;
using eRents.Features.ImageManagement.Models;

namespace eRents.Features.ImageManagement.Mapping;

public sealed class ImageMappingProfile : Profile
{
    public ImageMappingProfile()
    {
        // Entity -> Response
        CreateMap<Image, ImageResponse>();

        // Request -> Entity (ignore identity/audit; compute defaults)
        CreateMap<ImageRequest, Image>()
            .ForMember(d => d.ImageId, o => o.Ignore())
            .ForMember(d => d.CreatedAt, o => o.Ignore())
            .ForMember(d => d.CreatedBy, o => o.Ignore())
            .ForMember(d => d.UpdatedAt, o => o.Ignore())
            .AfterMap((src, dest) =>
            {
                // Default DateUploaded
                if (dest.DateUploaded == null)
                    dest.DateUploaded = DateTime.UtcNow;

                // Derive FileSizeBytes if data present
                if (!dest.FileSizeBytes.HasValue && dest.ImageData != null)
                    dest.FileSizeBytes = dest.ImageData.LongLength;
            });
    }
}
