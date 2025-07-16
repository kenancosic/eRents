using eRents.Domain.Models;
using eRents.Domain.Models.Enums;
using eRents.Features.ReviewManagement.DTOs;

namespace eRents.Features.ReviewManagement.Mappers;

/// <summary>
/// ReviewManagement Mapper - Entity to DTO conversions
/// Following modular architecture principles
/// </summary>
public static class ReviewMapper
{
    #region Review Entity Mappings

    /// <summary>
    /// Maps Review entity to ReviewResponse DTO - Aligned with frontend expectations
    /// </summary>
    public static ReviewResponse ToDto(Review review)
    {
        return new ReviewResponse
        {
            Id = review.ReviewId,
            ReviewType = GetReviewTypeString(review),
            PropertyId = review.PropertyId,
            RevieweeId = review.RevieweeId,
            ReviewerId = review.ReviewerId,
            BookingId = review.BookingId,
            StarRating = review.StarRating.HasValue ? (double)review.StarRating.Value : null,
            Description = review.Description ?? string.Empty,
            CreatedAt = review.CreatedAt,
            ParentReviewId = review.ParentReviewId,
            ImageIds = review.Images?.Select(i => i.ImageId).ToList() ?? new List<int>(),
            ReplyCount = review.Replies?.Count ?? 0,
            
            // Navigation properties
            UserFirstNameReviewer = review.Reviewer?.FirstName,
            UserLastNameReviewer = review.Reviewer?.LastName,
            UserFirstNameReviewee = review.Reviewee?.FirstName,
            UserLastNameReviewee = review.Reviewee?.LastName,
            PropertyName = review.Property?.Name
        };
    }

    /// <summary>
    /// Maps ReviewRequest DTO to Review entity - Aligned with frontend expectations
    /// </summary>
    public static Review ToEntity(ReviewRequest request)
    {
        return new Review
        {
            PropertyId = request.PropertyId,
            BookingId = request.BookingId,
            ParentReviewId = request.ParentReviewId,
            Description = request.Description,
            StarRating = request.StarRating > 0 ? (decimal)request.StarRating : null,

            ReviewType = GetReviewTypeFromString(request.ReviewType)
        };
    }

    /// <summary>
    /// Maps ReviewReplyRequest DTO to Review entity (for replies) - Aligned with frontend expectations
    /// </summary>
    public static Review ToReplyEntity(ReviewReplyRequest request)
    {
        return new Review
        {
            ParentReviewId = request.ParentReviewId,
            Description = request.Description,
            StarRating = null, // Replies don't have ratings

            ReviewType = ReviewType.ResponseReview
        };
    }

    /// <summary>
    /// Updates existing Review entity with ReviewRequest data - Aligned with frontend expectations
    /// </summary>
    public static void UpdateEntity(Review review, ReviewRequest request)
    {
        review.Description = request.Description;
        review.StarRating = request.StarRating > 0 ? (decimal)request.StarRating : null;
        // PropertyId, BookingId, ParentReviewId typically shouldn't change after creation
    }

    #endregion

    #region Collection Mappings

    /// <summary>
    /// Maps collection of Review entities to ReviewResponse DTOs
    /// </summary>
    public static List<ReviewResponse> ToDto(IEnumerable<Review> reviews)
    {
        return reviews.Select(ToDto).ToList();
    }

    /// <summary>
    /// Maps reviews to paginated response with statistics - Aligned with frontend expectations
    /// </summary>
    public static ReviewPagedResponse ToPagedResponse(
        IEnumerable<Review> reviews, 
        int totalCount, 
        int page, 
        int pageSize,
        ReviewStatisticsResponse? statistics = null)
    {
        var reviewDtos = ToDto(reviews);
        var totalPages = (int)Math.Ceiling((double)totalCount / pageSize);

        return new ReviewPagedResponse
        {
            Reviews = reviewDtos,
            TotalCount = totalCount,
            Page = page,
            PageSize = pageSize,
            TotalPages = totalPages,
            HasNextPage = page < totalPages,
            HasPreviousPage = page > 1,
            Statistics = statistics
        };
    }

    #endregion

    #region Statistics Mappings

    /// <summary>
    /// Creates ReviewStatisticsResponse from reviews collection - Aligned with frontend expectations
    /// </summary>
    public static ReviewStatisticsResponse ToStatisticsDto(int propertyId, IEnumerable<Review> reviews)
    {
        var reviewsList = reviews.Where(r => !r.ParentReviewId.HasValue).ToList(); // Only original reviews for stats
        var totalReviews = reviewsList.Count;
        var averageRating = totalReviews > 0 ? reviewsList.Average(r => r.StarRating ?? 0) : 0;

        return new ReviewStatisticsResponse
        {
            PropertyId = propertyId,
            TotalReviews = totalReviews,
            AverageRating = Math.Round((double)averageRating, 2),
            FiveStarCount = reviewsList.Count(r => r.StarRating == 5),
            FourStarCount = reviewsList.Count(r => r.StarRating == 4),
            ThreeStarCount = reviewsList.Count(r => r.StarRating == 3),
            TwoStarCount = reviewsList.Count(r => r.StarRating == 2),
            OneStarCount = reviewsList.Count(r => r.StarRating == 1),
            LatestReviewDate = reviewsList.OrderByDescending(r => r.CreatedAt).FirstOrDefault()?.CreatedAt,
            ReplyCount = reviews.Count(r => r.ParentReviewId.HasValue)
        };
    }

    /// <summary>
    /// Creates UserReviewSummaryResponse from user's reviews - Aligned with frontend expectations
    /// </summary>
    public static UserReviewSummaryResponse ToUserSummaryDto(int userId, IEnumerable<Review> userReviews)
    {
        var originalReviews = userReviews.Where(r => !r.ParentReviewId.HasValue).ToList();
        var repliesReceived = userReviews.Where(r => r.ParentReviewId.HasValue).Count();

        return new UserReviewSummaryResponse
        {
            UserId = userId,
            TotalReviewsGiven = originalReviews.Count,
            TotalRepliesReceived = repliesReceived,
            AverageRatingGiven = originalReviews.Count > 0 ? Math.Round((double)originalReviews.Average(r => r.StarRating ?? 0), 2) : 0,
            LastReviewDate = originalReviews.OrderByDescending(r => r.CreatedAt).FirstOrDefault()?.CreatedAt
        };
    }

    /// <summary>
    /// Creates RatingBreakdownResponse from reviews - Aligned with frontend expectations
    /// </summary>
    public static RatingBreakdownResponse ToRatingBreakdownDto(int propertyId, IEnumerable<Review> reviews)
    {
        var originalReviews = reviews.Where(r => !r.ParentReviewId.HasValue).ToList();
        var totalRatings = originalReviews.Count;
        var overallRating = totalRatings > 0 ? originalReviews.Average(r => r.StarRating ?? 0) : 0;

        var ratingDistribution = new Dictionary<int, int>();
        var ratingPercentages = new Dictionary<int, double>();

        for (int i = 1; i <= 5; i++)
        {
            var count = originalReviews.Count(r => r.StarRating == i);
            ratingDistribution[i] = count;
            ratingPercentages[i] = totalRatings > 0 ? Math.Round((double)count / totalRatings * 100, 1) : 0;
        }

        return new RatingBreakdownResponse
        {
            PropertyId = propertyId,
            OverallRating = Math.Round((double)overallRating, 2),
            TotalRatings = totalRatings,
            RatingDistribution = ratingDistribution,
            RatingPercentages = ratingPercentages,
            MostRecentRating = originalReviews.OrderByDescending(r => r.CreatedAt).FirstOrDefault()?.CreatedAt,
            OldestRating = originalReviews.OrderBy(r => r.CreatedAt).FirstOrDefault()?.CreatedAt
        };
    }

    #endregion



    #region Utility Methods

    /// <summary>
    /// Determines if a user can reply to a review
    /// </summary>
    public static bool CanUserReply(Review review, int userId, bool isPropertyOwner)
    {
        // Only original reviews can receive replies
        if (review.ParentReviewId.HasValue)
            return false;

        // Property owners can always reply to reviews on their properties
        if (isPropertyOwner)
            return true;

        // Users can reply to reviews they haven't already replied to
        // This would need additional logic to check existing replies
        return false;
    }

    /// <summary>
    /// Gets display text for review status
    /// </summary>
    public static string GetStatusDisplayText(string status)
    {
        return status switch
        {
            "Published" => "Published",
            "Pending" => "Pending Approval",
            "Hidden" => "Hidden",
            "Rejected" => "Rejected",
            _ => "Unknown"
        };
    }

    #endregion

    #region Helper Methods

    /// <summary>
    /// Gets review type string based on review properties
    /// </summary>
    private static string GetReviewTypeString(Review review)
    {
        return review.ReviewType switch
        {
            ReviewType.PropertyReview => "propertyReview",
            ReviewType.TenantReview => "tenantReview",
            ReviewType.ResponseReview => "responseReview",
            _ => "propertyReview" // Default
        };
    }

    /// <summary>
    /// Gets ReviewType enum from string
    /// </summary>
    private static ReviewType GetReviewTypeFromString(string reviewType)
    {
        return reviewType switch
        {
            "propertyReview" => ReviewType.PropertyReview,
            "tenantReview" => ReviewType.TenantReview,
            "responseReview" => ReviewType.ResponseReview,
            _ => ReviewType.PropertyReview // Default
        };
    }

    #endregion
}
