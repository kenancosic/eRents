using System;
using System.Collections.Generic;

namespace eRents.Shared.DTO.Response
{
	public class ReviewResponse
	{
		// Direct review entity fields - use exact entity field names
		public int ReviewId { get; set; }
		public string ReviewType { get; set; } // "PropertyReview" or "TenantReview"
		public int? PropertyId { get; set; }
		public int? RevieweeId { get; set; } // For tenant reviews
		public int? ReviewerId { get; set; }
		public string Description { get; set; }
		public DateTime DateCreated { get; set; }
		public decimal? StarRating { get; set; } // Optional for replies
		public int? BookingId { get; set; } // Optional for replies
		public int? ParentReviewId { get; set; } // For threaded conversations
		public List<int> ImageIds { get; set; } = new List<int>(); // Use ImageController to fetch images
		public List<ReviewResponse> Replies { get; set; } = new List<ReviewResponse>(); // Child replies
		public int ReplyCount { get; set; } // Total number of replies
		
		// Fields from other entities - use "EntityName + FieldName" pattern
		public string? UserFirstNameReviewer { get; set; }  // Reviewer's first name
		public string? UserLastNameReviewer { get; set; }   // Reviewer's last name
		public string? UserFirstNameReviewee { get; set; }  // Reviewee's first name (for tenant reviews)
		public string? UserLastNameReviewee { get; set; }   // Reviewee's last name (for tenant reviews)
		public string? PropertyName { get; set; }           // Property name
		
		        // Computed properties for UI convenience (for backward compatibility)
        public string? ReviewerName { get; set; }
		        public string? RevieweeName { get; set; }
	}
}
