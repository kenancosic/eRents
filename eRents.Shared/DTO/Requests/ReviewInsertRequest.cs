namespace eRents.Shared.DTO.Requests
{
	public class ReviewInsertRequest
	{
		public int? TenantId { get; set; }
		public int? PropertyId { get; set; }
		public string? Description { get; set; }
		public string? Severity { get; set; }
		public DateTime? DateReported { get; set; }
		public string? Status { get; set; }
		public bool IsComplaint { get; set; }
		public bool IsFlagged { get; set; }
		public decimal? StarRating { get; set; }
	}
}
