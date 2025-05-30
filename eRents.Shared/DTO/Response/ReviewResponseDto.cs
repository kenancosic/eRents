namespace eRents.Shared.DTO.Response
{
    public class ReviewResponseDto
    {
        public int Id { get; set; }
        public string ReviewType { get; set; } = null!; // PropertyReview or TenantReview
        public int? PropertyId { get; set; }
        public int? RevieweeId { get; set; } // For tenant reviews
        public int? ReviewerId { get; set; }
        public int? BookingId { get; set; }
        public decimal? StarRating { get; set; }
        public string Description { get; set; } = null!;
        public DateTime DateCreated { get; set; }
        public int? ParentReviewId { get; set; } // For threaded replies
        
        // Additional display information (can be set by service)
        public string? ReviewerName { get; set; }
        public string? RevieweeName { get; set; }
        public string? PropertyName { get; set; }
        public List<ReviewResponseDto>? Replies { get; set; }
    }
} 