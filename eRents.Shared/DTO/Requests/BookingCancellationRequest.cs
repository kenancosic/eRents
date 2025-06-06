using eRents.Shared.DTO.Base;

namespace eRents.Shared.DTO.Requests
{
	public class BookingCancellationRequest : BaseInsertRequest
	{
		public int BookingId { get; set; }
		public string? CancellationReason { get; set; }
		public bool RequestRefund { get; set; } = true;
		public string? AdditionalNotes { get; set; }
		
		// Optional: Guest-provided cancellation details
		public DateTime? PreferredRefundDate { get; set; }
		public string? RefundMethod { get; set; } = "Original Payment Method"; // PayPal, Bank Transfer, etc.
	}
} 