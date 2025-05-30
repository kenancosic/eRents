using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace eRents.Shared.DTO.Requests
{
	public class ReviewInsertRequest
	{
		public int? ReviewerId { get; set; } // Set by service based on current user

		[Required]
		public string ReviewType { get; set; } // "PropertyReview" or "TenantReview"

		public int? PropertyId { get; set; } // Required for property reviews, optional for tenant reviews

		public int? RevieweeId { get; set; } // Required for tenant reviews (the tenant being reviewed)

		public int? BookingId { get; set; } // Required for original reviews, optional for replies

		[Range(1, 5)]
		public decimal? StarRating { get; set; } // 1-5 stars, optional (null for replies without rating)

		[Required, StringLength(1000)]
		public string Description { get; set; } = string.Empty;

		public int? ParentReviewId { get; set; } // null for original reviews, set for replies

		public List<int> ImageIds { get; set; } = new List<int>();
	}
}
