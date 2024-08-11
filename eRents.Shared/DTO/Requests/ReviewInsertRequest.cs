namespace eRents.Shared.DTO.Requests
{
	public class ReviewInsertRequest
	{
		public int PropertyId { get; set; }
		public int TenantId { get; set; }
		public decimal StarRating { get; set; }  // Rating out of 5.0
		public string? Description { get; set; }
	}
}
