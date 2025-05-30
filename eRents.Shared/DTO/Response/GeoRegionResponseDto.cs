namespace eRents.Shared.DTO.Response
{
    public class GeoRegionResponseDto
    {
        public int GeoRegionId { get; set; }
        public string City { get; set; } = null!;
        public string? State { get; set; }
        public string Country { get; set; } = null!;
        public string? PostalCode { get; set; }
    }
} 