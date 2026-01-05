using System;
using eRents.Domain.Models.Enums;

namespace eRents.Features.ReviewManagement.Models;

public class ReviewResponse
{
    public int ReviewId { get; set; }
    public ReviewType ReviewType { get; set; }
    public int? PropertyId { get; set; }
    public int? RevieweeId { get; set; }
    public int? ReviewerId { get; set; }
    public string? ReviewerFirstName { get; set; }
    public string? ReviewerLastName { get; set; }
    public string? Description { get; set; }
    public decimal? StarRating { get; set; }
    public int? BookingId { get; set; }
    public int? ParentReviewId { get; set; }

    public DateTime CreatedAt { get; set; }
    public string? CreatedBy { get; set; }
    public DateTime UpdatedAt { get; set; }
    public string? UpdatedBy { get; set; }

    // Optional computed; may be populated in service-level projections if needed.
    public int? RepliesCount { get; set; }
}