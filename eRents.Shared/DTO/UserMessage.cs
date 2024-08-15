namespace eRents.Shared.DTO
{
	public class UserMessage
	{
		public string SenderUsername { get; set; } = null!;
		public string RecipientUsername { get; set; } = null!;
		public string Subject { get; set; } = null!;
		public string Body { get; set; } = null!;
	}
}
