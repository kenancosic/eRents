using eRents.Shared.Enums;

namespace eRents.Shared.SearchObjects
{
	public class ReviewSearchObject : BaseSearchObject
	{
		// ✅ AUTOMATIC: Direct property matches (exact entity property names)
		public int? PropertyId { get; set; }           // → entity.PropertyId
		public int? RevieweeId { get; set; }           // → entity.RevieweeId (tenant being reviewed)
		public int? ReviewerId { get; set; }           // → entity.ReviewerId (user who wrote review)
		public int? BookingId { get; set; }            // → entity.BookingId
		public int? ParentReviewId { get; set; }       // → entity.ParentReviewId (for threaded reviews)
		public string? Description { get; set; }       // → entity.Description

		// ✅ AUTOMATIC: Range filtering (Min/Max pairs)
		public decimal? MinStarRating { get; set; }    // → entity.StarRating >=
		public decimal? MaxStarRating { get; set; }    // → entity.StarRating <=
		public DateTime? MinDateCreated { get; set; }  // → entity.DateCreated >=
		public DateTime? MaxDateCreated { get; set; }  // → entity.DateCreated <=

		// ✅ AUTOMATIC: Enum filtering
		public ReviewType? ReviewType { get; set; }    // → entity.ReviewType (PropertyReview or TenantReview)

		// ⚙️ HELPER: Navigation properties (require custom implementation)
		public string? PropertyName { get; set; }      // → entity.Property.Name
		public string? ReviewerName { get; set; }      // → entity.Reviewer.FirstName + LastName
		public string? RevieweeName { get; set; }      // → entity.Reviewee.FirstName + LastName
		public bool? HasReplies { get; set; }          // → entity.Replies.Any()
		public bool? IsOriginalReview { get; set; }    // → entity.ParentReviewId == null

		// DEPRECATED: Keeping for backward compatibility (remove in next version)
		[Obsolete("Use MinStarRating/MaxStarRating instead")]
		public decimal? MinRating { get; set; }
		[Obsolete("Use MinStarRating/MaxStarRating instead")]
		public decimal? MaxRating { get; set; }
		[Obsolete("Use RevieweeId instead")]
		public int? TenantId { get; set; }

		// Note: SortBy and SortDescending are now inherited from BaseSearchObject
		// SortBy supports: "StarRating", "DateCreated", "PropertyId", "ReviewType", etc.
		// Navigation sorting: "PropertyName", "ReviewerName", "RevieweeName"
	}
}
