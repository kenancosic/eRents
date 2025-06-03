using System;
using eRents.Shared.DTO.Base;

namespace eRents.Shared.DTO.Response
{
    public class PropertySummaryResponse : BaseResponse
    {
        // Minimal for list views
        public string Name { get; set; }
        public decimal Price { get; set; }
        public string LocationString { get; set; }
        public int CoverImageId { get; set; }
        public double? AverageRating { get; set; }
    }
} 