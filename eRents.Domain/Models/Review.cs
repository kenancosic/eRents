using System;
using System.Collections.Generic;
using eRents.Domain.Shared;
using eRents.Shared.Enums;

namespace eRents.Domain.Models;

public partial class Review : BaseEntity
{
    public int ReviewId { get; set; }

    public ReviewType ReviewType { get; set; } // Distinguish between property and tenant reviews

    // For Property Reviews: PropertyId is the property being reviewed
    // For Tenant Reviews: PropertyId can be null or the property where tenant stayed
    public int? PropertyId { get; set; }

    // For Property Reviews: RevieweeId is null (reviewing the property itself)
    // For Tenant Reviews: RevieweeId is the tenant being reviewed
    public int? RevieweeId { get; set; } // User being reviewed (for tenant reviews)

    public int? ReviewerId { get; set; } // User who wrote the review

    public string? Description { get; set; }

    public DateTime DateCreated { get; set; } = DateTime.UtcNow;

    public decimal? StarRating { get; set; } // 1-5 stars, optional (null for replies without rating)

    public int? BookingId { get; set; } // Required for original reviews, optional for replies

    // Threading system for conversations (replies to reviews)
    public int? ParentReviewId { get; set; } // null for original reviews, points to parent for replies

    // Navigation properties
    public virtual ICollection<Image> Images { get; set; } = new List<Image>();
    public virtual Property? Property { get; set; }
    public virtual Booking? Booking { get; set; }
    public virtual User? Reviewer { get; set; } // The user who wrote the review
    public virtual User? Reviewee { get; set; } // The user being reviewed (for tenant reviews)
    
    // Self-referencing navigation for threaded conversations
    public virtual Review? ParentReview { get; set; }
    public virtual ICollection<Review> Replies { get; set; } = new List<Review>();
}
