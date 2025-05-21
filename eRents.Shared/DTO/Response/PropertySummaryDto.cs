using System;

namespace eRents.Shared.DTO.Response
{
    public class PropertySummaryDto
    {
        public string PropertyId { get; set; }
        public string Name { get; set; }
        public string LocationString { get; set; }
        public decimal Price { get; set; }
        public double? AverageRating { get; set; }
        public int ReviewCount { get; set; }
        public string ImageUrl { get; set; }
        public int? Rooms { get; set; }
        public double? Area { get; set; }
    }
} 