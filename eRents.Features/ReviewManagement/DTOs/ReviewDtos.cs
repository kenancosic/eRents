using eRents.Features.Shared.DTOs;
using System.ComponentModel.DataAnnotations;

namespace eRents.Features.ReviewManagement.DTOs;

/// <summary>
/// Review response DTO - Aligned with frontend expectations
/// </summary>
public class ReviewResponse
{
    public int Id { get; set; }
    public string ReviewType { get; set; } = "propertyReview";
    public int? PropertyId { get; set; }
    public int? RevieweeId { get; set; }
    public int? ReviewerId { get; set; }
    public int? BookingId { get; set; }
    public double? StarRating { get; set; }
    public string Description { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public int? ParentReviewId { get; set; }
    public List<int> ImageIds { get; set; } = new();
    public List<ReviewResponse> Replies { get; set; } = new();
    public int ReplyCount { get; set; }
    
    // Navigation properties for UI convenience
    public string? UserFirstNameReviewer { get; set; }
    public string? UserLastNameReviewer { get; set; }
    public string? UserFirstNameReviewee { get; set; }
    public string? UserLastNameReviewee { get; set; }
    public string? PropertyName { get; set; }
    

}

/// <summary>
/// Review request for creating new reviews - Aligned with frontend expectations
/// </summary>
public class ReviewRequest
{
    [Required]
    public int PropertyId { get; set; }
    
    public int? BookingId { get; set; }
    
    [Required]
    [StringLength(2000)]
    public string Description { get; set; } = string.Empty;
    
    [Required]
    [Range(1, 5)]
    public double StarRating { get; set; }
    
    public int? ParentReviewId { get; set; }
    
    public string ReviewType { get; set; } = "propertyReview";
    
    public List<int> ImageIds { get; set; } = new();
}

/// <summary>
/// Review update request
/// </summary>
public class ReviewUpdateRequest
{
    [StringLength(200)]
    public string? Title { get; set; }
    
    [StringLength(2000)]
    public string? Content { get; set; }
    
    [Range(1, 5)]
    public int? Rating { get; set; }
}

/// <summary>
/// Review statistics response - Aligned with frontend expectations
/// </summary>
public class ReviewStatisticsResponse
{
    public int PropertyId { get; set; }
    public int TotalReviews { get; set; }
    public double AverageRating { get; set; }
    public int FiveStarCount { get; set; }
    public int FourStarCount { get; set; }
    public int ThreeStarCount { get; set; }
    public int TwoStarCount { get; set; }
    public int OneStarCount { get; set; }
    public int ReplyCount { get; set; }
    public DateTime? LatestReviewDate { get; set; }
}



/// <summary>
/// Review reply request - Aligned with frontend expectations
/// </summary>
public class ReviewReplyRequest
{
    [Required]
    public int ParentReviewId { get; set; }
    
    [Required]
    [StringLength(2000)]
    public string Description { get; set; } = string.Empty;
    
    public string ReviewType { get; set; } = "responseReview";
    
    public List<int> ImageIds { get; set; } = new();
}

/// <summary>
/// Review filter request - Aligned with frontend expectations
/// </summary>
public class ReviewFilterRequest
{
    public int? PropertyId { get; set; }
    public int? ReviewerId { get; set; } // Changed from UserId to match frontend
    public int? RevieweeId { get; set; } // Added for tenant reviews
    public int? BookingId { get; set; } // Added for booking-specific reviews
    public int? ParentReviewId { get; set; } // Added for reply filtering
    public double? MinRating { get; set; } // Changed from int to double
    public double? MaxRating { get; set; } // Changed from int to double
    public DateTime? StartDate { get; set; }
    public DateTime? EndDate { get; set; }
    public string? SearchTerm { get; set; }
    public bool? IncludeReplies { get; set; } = false;
    public string? SortBy { get; set; } = "CreatedAt";
    public string? SortOrder { get; set; } = "DESC";
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 10;
}

/// <summary>
/// Review paged response
/// </summary>
public class ReviewPagedResponse
{
    public List<ReviewResponse> Reviews { get; set; } = new();
    public int TotalCount { get; set; }
    public int Page { get; set; }
    public int PageSize { get; set; }
    public int TotalPages { get; set; }
    public bool HasNextPage { get; set; }
    public bool HasPreviousPage { get; set; }
    public ReviewStatisticsResponse? Statistics { get; set; }
}

/// <summary>
/// User review summary response
/// </summary>
public class UserReviewSummaryResponse
{
    public int UserId { get; set; }
    public string UserName { get; set; } = string.Empty;
    public int TotalReviewsGiven { get; set; }
    public int TotalRepliesReceived { get; set; }
    public double AverageRatingGiven { get; set; }
    public DateTime? LastReviewDate { get; set; }
    public int HelpfulVotesReceived { get; set; }
    public string ReviewerLevel { get; set; } = string.Empty;
}

/// <summary>
/// Rating breakdown response
/// </summary>
public class RatingBreakdownResponse
{
    public int PropertyId { get; set; }
    public string PropertyName { get; set; } = string.Empty;
    public double OverallRating { get; set; }
    public int TotalRatings { get; set; }
    public Dictionary<int, int> RatingDistribution { get; set; } = new();
    public Dictionary<int, double> RatingPercentages { get; set; } = new();
    public DateTime? MostRecentRating { get; set; }
    public DateTime? OldestRating { get; set; }
}




