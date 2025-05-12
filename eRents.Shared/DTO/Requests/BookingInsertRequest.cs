namespace eRents.Shared.DTO.Requests
{
	public class BookingInsertRequest
	{
		public int PropertyId { get; set; }
		public int UserId { get; set; }
		public DateOnly StartDate { get; set; }
		public DateOnly EndDate { get; set; }
		public decimal TotalPrice { get; set; }
		public string? PaymentMethod { get; set; }
		public int NumberOfGuests { get; set; }
		public string? SpecialRequests { get; set; }
	}
}