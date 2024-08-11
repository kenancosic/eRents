namespace eRents.Shared.DTO
{
	public class UserMessage
	{
		public string? SenderEmail { get; set; }
		public string? RecipientEmail { get; set; }
		public string? Subject { get; set; }
		public string? Body { get; set; }
	}
}
