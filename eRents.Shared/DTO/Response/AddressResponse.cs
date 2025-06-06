namespace eRents.Shared.DTO.Response
{
    /// <summary>
    /// Simplified Address response DTO that aligns with the Address value object.
    /// Replaces the complex AddressDetailResponse + GeoRegionResponse structure.
    /// </summary>
    public class AddressResponse
    {
        public string? StreetLine1 { get; set; }
        public string? StreetLine2 { get; set; }
        public string? City { get; set; }
        public string? State { get; set; }
        public string? Country { get; set; }
        public string? PostalCode { get; set; }
        public decimal? Latitude { get; set; }
        public decimal? Longitude { get; set; }
        
        /// <summary>
        /// Gets the full address as a formatted string
        /// </summary>
        public string? FullAddress => GetFullAddress();
        
        /// <summary>
        /// Gets the location part (city, state, country)
        /// </summary>
        public string? LocationString => GetLocationString();
        
        private string? GetFullAddress()
        {
            var parts = new[] { StreetLine1, StreetLine2, City, State, Country, PostalCode }
                .Where(x => !string.IsNullOrEmpty(x));
            return parts.Any() ? string.Join(", ", parts) : null;
        }
        
        private string? GetLocationString()
        {
            var parts = new[] { City, State, Country }
                .Where(x => !string.IsNullOrEmpty(x));
            return parts.Any() ? string.Join(", ", parts) : null;
        }
    }
} 