namespace eRents.Shared.DTO.Response
{
	public class ReviewResponse
	{
		public int ReviewId { get; set; }
		public int? PropertyId { get; set; }
		public string? Description { get; set; }
		public DateTime? DateReported { get; set; }
		public decimal? StarRating { get; set; }
		public int? BookingId { get; set; }
		public List<ImageResponse> Images { get; set; } = new List<ImageResponse>();
	}
}
