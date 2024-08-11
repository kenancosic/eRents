namespace eRents.Shared.DTO.Response
{
	public class BookingResponse
	{
		public int BookingId { get; set; }
		public int PropertyId { get; set; }
		public int UserId { get; set; }
		public DateTime StartDate { get; set; }
		public DateTime EndDate { get; set; }
		public decimal TotalPrice { get; set; }
		public string Status { get; set; }
	}
}
