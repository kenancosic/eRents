namespace eRents.Shared.Messaging
{
	public class UserMessage
	{
		public string? SenderUsername { get; set; }
		public string? RecipientUsername { get; set; }
		public string? Subject { get; set; }
		public string? Body { get; set; }
	}
} 