namespace eRents.Shared.DTO.Response
{
	public class ReviewResponse
	{
		public int ReviewId { get; set; }
		public int PropertyId { get; set; }
		public int TenantId { get; set; }
		public string Description { get; set; }
		public string Severity { get; set; }
		public DateTime DateReported { get; set; }
		public string Status { get; set; }
		public bool Complain { get; set; }
		public decimal? StarRating { get; set; }
		public bool IsFlagged { get; set; }
		public List<ImageResponse> Images { get; set; } // Include images in the response
	}

}
