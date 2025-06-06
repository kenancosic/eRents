using System.ComponentModel.DataAnnotations;

namespace eRents.Shared.DTO.Requests
{
    /// <summary>
    /// Simplified Address request DTO that aligns with the Address value object.
    /// Replaces the complex AddressDetailRequest + GeoRegionRequest structure.
    /// </summary>
    public class AddressRequest
    {
        [StringLength(255)]
        public string? StreetLine1 { get; set; }
        
        [StringLength(255)]
        public string? StreetLine2 { get; set; }
        
        [StringLength(100)]
        public string? City { get; set; }
        
        [StringLength(100)]
        public string? State { get; set; }
        
        [StringLength(100)]
        public string? Country { get; set; }
        
        [StringLength(20)]
        public string? PostalCode { get; set; }
        
        [Range(-90, 90)]
        public decimal? Latitude { get; set; }
        
        [Range(-180, 180)]
        public decimal? Longitude { get; set; }
    }
} 