namespace eRents.Shared.DTO.Requests
{
	/// <summary>
	/// Request DTO for processing payment refunds
	/// </summary>
	public class RefundRequest
	{
		/// <summary>
		/// The original payment reference to refund
		/// </summary>
		public string OriginalPaymentReference { get; set; } = string.Empty;

		/// <summary>
		/// Amount to refund (can be partial)
		/// </summary>
		public decimal RefundAmount { get; set; }

		/// <summary>
		/// Currency of the refund
		/// </summary>
		public string Currency { get; set; } = "BAM";

		/// <summary>
		/// Reason for the refund
		/// </summary>
		public string? Reason { get; set; }

		/// <summary>
		/// Associated booking ID if applicable
		/// </summary>
		public int? BookingId { get; set; }
	}
} 