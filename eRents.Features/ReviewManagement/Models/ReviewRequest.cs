using eRents.Domain.Models.Enums;

namespace eRents.Features.ReviewManagement.Models;

public class ReviewRequest
{
    public ReviewType ReviewType { get; set; }

    public int? PropertyId { get; set; }

    public int? RevieweeId { get; set; }

    public int? ReviewerId { get; set; }

    public string? Description { get; set; }

    public decimal? StarRating { get; set; }

    public int? BookingId { get; set; }

    public int? ParentReviewId { get; set; }
}