namespace eRents.Shared.DTO.Requests
{
	public class ReviewUpdateRequest
	{
		public decimal StarRating { get; set; }  // Rating out of 5.0
		public string? Description { get; set; }
	}
}
