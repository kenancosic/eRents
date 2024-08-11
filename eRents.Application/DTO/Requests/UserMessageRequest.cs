namespace eRents.Application.DTO.Requests
{
	public class UserMessageRequest
	{
		public string SenderEmail { get; set; }
		public string RecipientEmail { get; set; }
		public string Subject { get; set; }
		public string Body { get; set; }
	}
}
