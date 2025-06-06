using System;
using eRents.Shared.DTO.Base;

namespace eRents.Shared.DTO.Response
{
    public class PropertySummaryResponse : BaseResponse
    {
        // ✅ DOMAIN-ALIGNED: Minimal fields for list views
        public int PropertyId { get; set; }  // Explicit PropertyId from domain
        public string Name { get; set; }     // Domain uses Name
        public decimal Price { get; set; }
        public string LocationString { get; set; }
        public int CoverImageId { get; set; }
        public double? AverageRating { get; set; }
        public DateTime? DateAdded { get; set; }  // Domain field name
    }
} 