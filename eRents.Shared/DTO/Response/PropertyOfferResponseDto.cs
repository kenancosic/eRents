namespace eRents.Shared.DTO.Response
{
    public class PropertyOfferResponseDto
    {
        public int OfferId { get; set; }
        public int TenantId { get; set; }
        public int PropertyId { get; set; }
        public int LandlordId { get; set; }
        public DateTime DateOffered { get; set; }
        public string Status { get; set; } = "Pending"; // Pending, Accepted, Rejected, Expired
        public string? Message { get; set; }
        
        // Property details for display
        public string? PropertyTitle { get; set; }
        public string? PropertyAddress { get; set; }
        public decimal? PropertyPrice { get; set; }
        public string? PropertyImageUrl { get; set; }
        
        // Tenant details for display
        public string? TenantFullName { get; set; }
        public string? TenantEmail { get; set; }
    }
} 