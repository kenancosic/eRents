namespace eRents.WebApi
{
	public class ErrorResponse
	{
		public int StatusCode { get; set; }
		public string Message { get; set; }
		public string DetailedMessage { get; set; }
	}
}