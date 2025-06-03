namespace eRents.Shared.DTO.Requests
{
    public class ReviewInsertRequest
    {
        public string ReviewType { get; set; } = null!; // PropertyReview or TenantReview
        public int? PropertyId { get; set; } // Required for property reviews
        public int? RevieweeId { get; set; } // Required for tenant reviews  
        public int? BookingId { get; set; } // Required for original reviews, optional for replies
        public decimal? StarRating { get; set; } // Required for original reviews, optional for replies
        public string Description { get; set; } = null!;
        public int? ParentReviewId { get; set; } // null for original reviews, set for replies
    }
} 