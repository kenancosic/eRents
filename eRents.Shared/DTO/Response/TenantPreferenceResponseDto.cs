namespace eRents.Shared.DTO.Response
{
    public class TenantPreferenceResponseDto
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public DateTime SearchStartDate { get; set; }
        public DateTime? SearchEndDate { get; set; }
        public decimal? MinPrice { get; set; }
        public decimal? MaxPrice { get; set; }
        public string City { get; set; } = null!;
        public List<string> Amenities { get; set; } = new List<string>();
        public string Description { get; set; } = string.Empty;
        public bool IsActive { get; set; }
        
        // User information for display purposes
        public string? UserFullName { get; set; }
        public string? UserEmail { get; set; }
        public string? UserPhone { get; set; }
        public string? UserCity { get; set; }
        public string? ProfileImageUrl { get; set; }
        
        // Match scoring for landlord tenant discovery
        public double MatchScore { get; set; }
        public List<string> MatchReasons { get; set; } = new List<string>();
    }
} 