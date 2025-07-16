using eRents.Features.ReviewManagement.DTOs;
using eRents.Features.ReviewManagement.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;

namespace eRents.Features.ReviewManagement.Controllers;

/// <summary>
/// Review management controller
/// Following modular architecture principles
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Authorize]
public class ReviewController : ControllerBase
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
        try
        {
            var review = await _reviewService.GetReviewByIdAsync(id);
            
            if (review == null)
                return NotFound($"Review with ID {id} not found");

            return Ok(review);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting review {ReviewId}", id);
            return StatusCode(500, "An error occurred while retrieving the review");
        }
    }

    /// <summary>
    /// Creates a new review
    /// </summary>
    [HttpPost]
    public async Task<ActionResult<ReviewResponse>> CreateReview([FromBody] ReviewRequest request)
    {
        try
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var review = await _reviewService.CreateReviewAsync(request);
            
            return CreatedAtAction(nameof(GetReview), new { id = review.Id }, review);
        }
        catch (UnauthorizedAccessException ex)
        {
            return Forbid(ex.Message);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating review for property {PropertyId}", request.PropertyId);
            return StatusCode(500, "An error occurred while creating the review");
        }
    }

    /// <summary>
    /// Updates an existing review
    /// </summary>
    [HttpPut("{id}")]
    public async Task<ActionResult<ReviewResponse>> UpdateReview(int id, [FromBody] ReviewRequest request)
    {
        try
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var review = await _reviewService.UpdateReviewAsync(id, request);
            
            return Ok(review);
        }
        catch (UnauthorizedAccessException ex)
        {
            return Forbid(ex.Message);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating review {ReviewId}", id);
            return StatusCode(500, "An error occurred while updating the review");
        }
    }

    /// <summary>
    /// Deletes a review
    /// </summary>
    [HttpDelete("{id}")]
    public async Task<ActionResult> DeleteReview(int id)
    {
        try
        {
            var result = await _reviewService.DeleteReviewAsync(id);
            
            if (!result)
                return NotFound($"Review with ID {id} not found");

            return NoContent();
        }
        catch (UnauthorizedAccessException ex)
        {
            return Forbid(ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting review {ReviewId}", id);
            return StatusCode(500, "An error occurred while deleting the review");
        }
    }

    /// <summary>
    /// Creates a reply to an existing review
    /// </summary>
    [HttpPost("reply")]
    public async Task<ActionResult<ReviewResponse>> CreateReply([FromBody] ReviewReplyRequest request)
    {
        try
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var reply = await _reviewService.CreateReplyAsync(request);
            
            return CreatedAtAction(nameof(GetReview), new { id = reply.Id }, reply);
        }
        catch (UnauthorizedAccessException ex)
        {
            return Forbid(ex.Message);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating reply to review {ParentReviewId}", request.ParentReviewId);
            return StatusCode(500, "An error occurred while creating the reply");
        }
    }

    #endregion

    #region Review Queries

    /// <summary>
    /// Gets paginated reviews with filtering
    /// </summary>
    [HttpPost("search")]
    public async Task<ActionResult<ReviewPagedResponse>> GetReviews([FromBody] ReviewFilterRequest filter)
    {
        try
        {
            var reviews = await _reviewService.GetReviewsAsync(filter);
            return Ok(reviews);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting reviews with filter");
            return StatusCode(500, "An error occurred while retrieving reviews");
        }
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
        try
        {
            var reviews = await _reviewService.GetPropertyReviewsAsync(propertyId, page, pageSize, includeReplies);
            return Ok(reviews);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting reviews for property {PropertyId}", propertyId);
            return StatusCode(500, "An error occurred while retrieving property reviews");
        }
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
        try
        {
            var reviews = await _reviewService.GetUserReviewsAsync(userId, page, pageSize);
            return Ok(reviews);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting reviews for user {UserId}", userId);
            return StatusCode(500, "An error occurred while retrieving user reviews");
        }
    }

    /// <summary>
    /// Gets replies for a specific review
    /// </summary>
    [HttpGet("{reviewId}/replies")]
    [AllowAnonymous] // Public replies for review viewing
    public async Task<ActionResult<List<ReviewResponse>>> GetReviewReplies(int reviewId)
    {
        try
        {
            var replies = await _reviewService.GetReviewRepliesAsync(reviewId);
            return Ok(replies);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting replies for review {ReviewId}", reviewId);
            return StatusCode(500, "An error occurred while retrieving review replies");
        }
    }

    /// <summary>
    /// Gets recent reviews across all properties
    /// </summary>
    [HttpGet("recent")]
    [AllowAnonymous] // Public recent reviews
    public async Task<ActionResult<List<ReviewResponse>>> GetRecentReviews(int count = 10)
    {
        try
        {
            var reviews = await _reviewService.GetRecentReviewsAsync(count);
            return Ok(reviews);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting recent reviews");
            return StatusCode(500, "An error occurred while retrieving recent reviews");
        }
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
        try
        {
            var statistics = await _reviewService.GetPropertyStatisticsAsync(propertyId);
            return Ok(statistics);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting statistics for property {PropertyId}", propertyId);
            return StatusCode(500, "An error occurred while retrieving property statistics");
        }
    }

    /// <summary>
    /// Gets user review summary
    /// </summary>
    [HttpGet("user/{userId}/summary")]
    public async Task<ActionResult<UserReviewSummaryResponse>> GetUserSummary(int userId)
    {
        try
        {
            var summary = await _reviewService.GetUserSummaryAsync(userId);
            return Ok(summary);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting summary for user {UserId}", userId);
            return StatusCode(500, "An error occurred while retrieving user summary");
        }
    }

    /// <summary>
    /// Gets detailed rating breakdown for a property
    /// </summary>
    [HttpGet("property/{propertyId}/rating-breakdown")]
    [AllowAnonymous] // Public rating breakdown for property viewing
    public async Task<ActionResult<RatingBreakdownResponse>> GetRatingBreakdown(int propertyId)
    {
        try
        {
            var breakdown = await _reviewService.GetRatingBreakdownAsync(propertyId);
            return Ok(breakdown);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting rating breakdown for property {PropertyId}", propertyId);
            return StatusCode(500, "An error occurred while retrieving rating breakdown");
        }
    }



    #endregion



    #region Authorization Helpers

    /// <summary>
    /// Checks if user can review a property
    /// </summary>
    [HttpGet("can-review/property/{propertyId}")]
    public async Task<ActionResult<bool>> CanUserReviewProperty(int propertyId)
    {
        try
        {
            // Get current user from claims (this would need proper implementation)
            var userIdClaim = User.FindFirst("UserId")?.Value;
            if (!int.TryParse(userIdClaim, out int userId))
                return Unauthorized("User ID not found in token");

            var canReview = await _reviewService.CanUserReviewPropertyAsync(userId, propertyId);
            return Ok(canReview);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error checking review permissions for property {PropertyId}", propertyId);
            return StatusCode(500, "An error occurred while checking review permissions");
        }
    }

    /// <summary>
    /// Checks if user can reply to a review
    /// </summary>
    [HttpGet("can-reply/review/{reviewId}")]
    public async Task<ActionResult<bool>> CanUserReplyToReview(int reviewId)
    {
        try
        {
            // Get current user from claims (this would need proper implementation)
            var userIdClaim = User.FindFirst("UserId")?.Value;
            if (!int.TryParse(userIdClaim, out int userId))
                return Unauthorized("User ID not found in token");

            var canReply = await _reviewService.CanUserReplyToReviewAsync(userId, reviewId);
            return Ok(canReply);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error checking reply permissions for review {ReviewId}", reviewId);
            return StatusCode(500, "An error occurred while checking reply permissions");
        }
    }

    #endregion


}
