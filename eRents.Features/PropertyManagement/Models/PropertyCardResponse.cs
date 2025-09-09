using System;

namespace eRents.Features.PropertyManagement.Models
{
    public sealed class PropertyCardResponse
    {
        public int PropertyId { get; set; }
        public string Name { get; set; } = string.Empty;
        public decimal Price { get; set; }
        public string Currency { get; set; } = string.Empty;
        public double? AverageRating { get; set; }
        public int? CoverImageId { get; set; }
        public eRents.Features.Shared.DTOs.AddressResponse? Address { get; set; }
        public string RentingType { get; set; } = string.Empty;
    }
}
