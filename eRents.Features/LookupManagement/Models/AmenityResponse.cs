namespace eRents.Features.LookupManagement.Models
{
    public class AmenityResponse
    {
        public int AmenityId { get; set; }
        public string AmenityName { get; set; } = null!;
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
    }
}