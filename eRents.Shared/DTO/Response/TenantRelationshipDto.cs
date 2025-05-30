namespace eRents.Shared.DTO.Response
{
    public class TenantRelationshipDto
    {
        public int TenantId { get; set; }
        public int UserId { get; set; }
        public int? PropertyId { get; set; }
        public DateTime? LeaseStartDate { get; set; }
        public DateTime? LeaseEndDate { get; set; }
        public string? TenantStatus { get; set; } // Active, Completed, Cancelled
        
        // User details
        public string UserFullName { get; set; } = null!;
        public string UserEmail { get; set; } = null!;
        public string? UserPhone { get; set; }
        public string? UserCity { get; set; }
        public string? ProfileImageUrl { get; set; }
        
        // Property details
        public string? PropertyTitle { get; set; }
        public string? PropertyAddress { get; set; }
        public double? PropertyPrice { get; set; }
        public string? PropertyImageUrl { get; set; }
        
        // Booking details
        public int? CurrentBookingId { get; set; }
        public DateTime? BookingStartDate { get; set; }
        public DateTime? BookingEndDate { get; set; }
        public string? BookingStatus { get; set; }
        public decimal? TotalPaid { get; set; }
        
        // Performance metrics
        public int TotalBookings { get; set; }
        public decimal TotalRevenue { get; set; }
        public double? AverageRating { get; set; }
        public int MaintenanceIssuesReported { get; set; }
    }
} 