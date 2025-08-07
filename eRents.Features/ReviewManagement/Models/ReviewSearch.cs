using System;
using eRents.Features.Core.Models;
using eRents.Domain.Models.Enums;

namespace eRents.Features.ReviewManagement.Models;

public class ReviewSearch : BaseSearchObject
{
    public int? PropertyId { get; set; }
    public int? ReviewerId { get; set; }
    public int? RevieweeId { get; set; }
    public ReviewType? ReviewType { get; set; }
    public int? BookingId { get; set; }
    public int? ParentReviewId { get; set; } // when set, returns the thread children

    public decimal? StarRatingMin { get; set; }
    public decimal? StarRatingMax { get; set; }

    public DateTime? CreatedFrom { get; set; }
    public DateTime? CreatedTo { get; set; }

    // SortBy: createdat | updatedat | starrating (default ReviewId)
    // SortDirection handled by base (asc|desc)
}