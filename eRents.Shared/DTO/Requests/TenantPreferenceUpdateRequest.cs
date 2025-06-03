namespace eRents.Shared.DTO.Requests
{
    public class TenantPreferenceUpdateRequest
    {
        public DateTime SearchStartDate { get; set; }
        public DateTime? SearchEndDate { get; set; }
        public decimal? MinPrice { get; set; }
        public decimal? MaxPrice { get; set; }
        public string City { get; set; } = null!;
        public List<string> Amenities { get; set; } = new List<string>();
        public string Description { get; set; } = string.Empty;
        public bool IsActive { get; set; }
    }
} 