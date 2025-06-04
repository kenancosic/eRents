using System;
using System.Collections.Generic;

namespace eRents.Shared.DTO.Response
{
	public class ReviewResponse
	{
		public int ReviewId { get; set; }
		public string ReviewType { get; set; } // "PropertyReview" or "TenantReview"
		public int? PropertyId { get; set; }
		public int? RevieweeId { get; set; } // For tenant reviews
		public int? ReviewerId { get; set; }
		public string ReviewerName { get; set; } // Computed field for display
		public string? RevieweeName { get; set; } // Computed field for tenant reviews
		public string? PropertyName { get; set; } // Computed field for display
		public string Description { get; set; }
		public DateTime DateCreated { get; set; }
		public decimal? StarRating { get; set; } // Optional for replies
		public int? BookingId { get; set; } // Optional for replies
		public int? ParentReviewId { get; set; } // For threaded conversations
		public List<int> ImageIds { get; set; } = new List<int>(); // Use ImageController to fetch images
		public List<ReviewResponse> Replies { get; set; } = new List<ReviewResponse>(); // Child replies
		public int ReplyCount { get; set; } // Total number of replies
	}
}
