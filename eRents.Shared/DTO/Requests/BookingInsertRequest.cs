namespace eRents.Shared.DTO.Requests
{
	public class BookingInsertRequest
	{
		public int PropertyId { get; set; }
		public int UserId { get; set; }
		public DateTime StartDate { get; set; }
		public DateTime EndDate { get; set; }
		public decimal TotalPrice { get; set; }
	}
}