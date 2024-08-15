namespace eRents.Shared.DTO
{
	public class ReviewNotificationMessage
	{
		public int PropertyId { get; set; }
		public int ReviewId { get; set; }
		public string? Message { get; set; }
	}
}
