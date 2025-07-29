using eRents.Features.ReviewManagement.DTOs;
using eRents.Features.ReviewManagement.Services;
using eRents.Features.Shared.Controllers;
using eRents.Features.Shared.Extensions;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;

namespace eRents.Features.ReviewManagement.Controllers;

/// <summary>
/// Review management controller
/// Following unified BaseController architecture with reduced boilerplate
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Authorize]
public class ReviewController : BaseController
{
    private readonly IReviewService _reviewService;
    private readonly ILogger<ReviewController> _logger;

    public ReviewController(
        IReviewService reviewService,
        ILogger<ReviewController> logger)
    {
        _reviewService = reviewService;
        _logger = logger;
    }

    #region Core Review Operations

    /// <summary>
    /// Gets a review by ID
    /// </summary>
    [HttpGet("{id}")]
    public async Task<ActionResult<ReviewResponse>> GetReview(int id)
    {
        return await this.GetByIdAsync<ReviewResponse, int>(id, _reviewService.GetReviewByIdAsync, _logger);
    }

    /// <summary>
    /// Creates a new review
    /// </summary>
    [HttpPost]
    public async Task<ActionResult<ReviewResponse>> CreateReview([FromBody] ReviewRequest request)
    {
        return await this.CreateAsync<ReviewRequest, ReviewResponse>(
            request,
            _reviewService.CreateReviewAsync,
            _logger,
            nameof(GetReview));
    }

    /// <summary>
    /// Updates an existing review
    /// </summary>
    [HttpPut("{id}")]
    public async Task<ActionResult<ReviewResponse>> UpdateReview(int id, [FromBody] ReviewRequest request)
    {
        return await this.UpdateAsync<ReviewRequest, ReviewResponse>(
            id,
            request,
            _reviewService.UpdateReviewAsync,
            _logger);
    }

    /// <summary>
    /// Deletes a review
    /// </summary>
    [HttpDelete("{id}")]
    public async Task<ActionResult> DeleteReview(int id)
    {
        return await this.DeleteAsync(
            id,
            _reviewService.DeleteReviewAsync,
            _logger);
    }

    /// <summary>
    /// Creates a reply to an existing review
    /// </summary>
    [HttpPost("reply")]
    public async Task<ActionResult<ReviewResponse>> CreateReply([FromBody] ReviewReplyRequest request)
    {
        return await this.CreateAsync<ReviewReplyRequest, ReviewResponse>(
            request,
            _reviewService.CreateReplyAsync,
            _logger,
            nameof(GetReview));
    }

    #endregion

    #region Review Queries

    /// <summary>
    /// Gets paginated reviews with filtering
    /// </summary>
    [HttpPost("search")]
    public async Task<ActionResult<ReviewPagedResponse>> GetReviews([FromBody] ReviewFilterRequest filter)
    {
        return await this.ExecuteAsync(() => _reviewService.GetReviewsAsync(filter), _logger, "GetReviews");
    }

    /// <summary>
    /// Gets reviews for a specific property
    /// </summary>
    [HttpGet("property/{propertyId}")]
    [AllowAnonymous] // Public reviews for property viewing
    public async Task<ActionResult<ReviewPagedResponse>> GetPropertyReviews(
        int propertyId,
        int page = 1,
        int pageSize = 10,
        bool includeReplies = false)
    {
        return await this.ExecuteAsync(
            () => _reviewService.GetPropertyReviewsAsync(propertyId, page, pageSize, includeReplies),
            _logger,
            "GetPropertyReviews");
    }

    /// <summary>
    /// Gets reviews by a specific user
    /// </summary>
    [HttpGet("user/{userId}")]
    public async Task<ActionResult<ReviewPagedResponse>> GetUserReviews(
        int userId,
        int page = 1,
        int pageSize = 10)
    {
        return await this.ExecuteAsync(
            () => _reviewService.GetUserReviewsAsync(userId, page, pageSize),
            _logger,
            "GetUserReviews");
    }

    /// <summary>
    /// Gets replies for a specific review
    /// </summary>
    [HttpGet("{reviewId}/replies")]
    [AllowAnonymous] // Public replies for review viewing
    public async Task<ActionResult<List<ReviewResponse>>> GetReviewReplies(int reviewId)
    {
        return await this.ExecuteAsync(
            () => _reviewService.GetReviewRepliesAsync(reviewId),
            _logger,
            "GetReviewReplies");
    }

    /// <summary>
    /// Gets recent reviews across all properties
    /// </summary>
    [HttpGet("recent")]
    [AllowAnonymous] // Public recent reviews
    public async Task<ActionResult<List<ReviewResponse>>> GetRecentReviews(int count = 10)
    {
        return await this.ExecuteAsync(
            () => _reviewService.GetRecentReviewsAsync(count),
            _logger,
            "GetRecentReviews");
    }

    #endregion

    #region Review Statistics

    /// <summary>
    /// Gets review statistics for a property
    /// </summary>
    [HttpGet("property/{propertyId}/statistics")]
    [AllowAnonymous] // Public statistics for property viewing
    public async Task<ActionResult<ReviewStatisticsResponse>> GetPropertyStatistics(int propertyId)
    {
        return await this.ExecuteAsync(
            () => _reviewService.GetPropertyStatisticsAsync(propertyId),
            _logger,
            "GetPropertyStatistics");
    }

    /// <summary>
    /// Gets user review summary
    /// </summary>
    [HttpGet("user/{userId}/summary")]
    public async Task<ActionResult<UserReviewSummaryResponse>> GetUserSummary(int userId)
    {
        return await this.ExecuteAsync(
            () => _reviewService.GetUserSummaryAsync(userId),
            _logger,
            "GetUserSummary");
    }

    /// <summary>
    /// Gets detailed rating breakdown for a property
    /// </summary>
    [HttpGet("property/{propertyId}/rating-breakdown")]
    [AllowAnonymous] // Public rating breakdown for property viewing
    public async Task<ActionResult<RatingBreakdownResponse>> GetRatingBreakdown(int propertyId)
    {
        return await this.ExecuteAsync(
            () => _reviewService.GetRatingBreakdownAsync(propertyId),
            _logger,
            "GetRatingBreakdown");
    }



    #endregion



    #region Authorization Helpers

    /// <summary>
    /// Checks if user can review a property
    /// </summary>
    [HttpGet("can-review/property/{propertyId}")]
    public async Task<ActionResult<bool>> CanUserReviewProperty(int propertyId)
    {
        // Get current user from claims (this would need proper implementation)
        var userIdClaim = User.FindFirst("UserId")?.Value;
        if (!int.TryParse(userIdClaim, out int userId))
            return Unauthorized("User ID not found in token");

        return await this.ExecuteAsync(
            () => _reviewService.CanUserReviewPropertyAsync(userId, propertyId),
            _logger,
            "CanUserReviewProperty");
    }

    /// <summary>
    /// Checks if user can reply to a review
    /// </summary>
    [HttpGet("can-reply/review/{reviewId}")]
    public async Task<ActionResult<bool>> CanUserReplyToReview(int reviewId)
    {
        // Get current user from claims (this would need proper implementation)
        var userIdClaim = User.FindFirst("UserId")?.Value;
        if (!int.TryParse(userIdClaim, out int userId))
            return Unauthorized("User ID not found in token");

        return await this.ExecuteAsync(
            () => _reviewService.CanUserReplyToReviewAsync(userId, reviewId),
            _logger,
            "CanUserReplyToReview");
    }

    #endregion


}
