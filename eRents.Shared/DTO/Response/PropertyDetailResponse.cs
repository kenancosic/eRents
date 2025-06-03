using System;
using System.Collections.Generic;

namespace eRents.Shared.DTO.Response
{
    public class PropertyDetailResponse : PropertyResponse
    {
        // Extended for detail views only
        public string PropertyTypeName { get; set; }
        public string StatusName { get; set; }
        public string OwnerName { get; set; }
        public double? AverageRating { get; set; }
        public List<ImageResponse> Images { get; set; } = new List<ImageResponse>();
        public List<AmenityResponse> Amenities { get; set; } = new List<AmenityResponse>();
    }
} 