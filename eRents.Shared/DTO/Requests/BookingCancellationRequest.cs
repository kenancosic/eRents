using eRents.Shared.DTO.Base;

namespace eRents.Shared.DTO.Requests
{
	/// <summary>
	/// Enhanced booking cancellation request with role-specific validation
	/// </summary>
	public class BookingCancellationRequest
	{
		/// <summary>
		/// ID of the booking to cancel
		/// </summary>
		public int BookingId { get; set; }

		/// <summary>
		/// Reason for cancellation (required for landlords)
		/// </summary>
		public string? CancellationReason { get; set; }

		/// <summary>
		/// Whether to request a refund
		/// </summary>
		public bool RequestRefund { get; set; } = true;

		/// <summary>
		/// Additional notes about the cancellation
		/// </summary>
		public string? AdditionalNotes { get; set; }

		/// <summary>
		/// Preferred refund method
		/// </summary>
		public string? RefundMethod { get; set; } = "Original";

		/// <summary>
		/// Emergency cancellation flag (for landlords)
		/// </summary>
		public bool IsEmergency { get; set; } = false;
	}

	/// <summary>
	/// Standard landlord cancellation reasons
	/// </summary>
	public static class LandlordCancellationReasons
	{
		public const string Emergency = "emergency";
		public const string Maintenance = "maintenance";
		public const string PropertyDamage = "property damage";
		public const string ForceMajeure = "force majeure";
		public const string Overbooking = "overbooking";
		public const string SchedulingConflict = "scheduling conflict";
		public const string HealthSafety = "health and safety concerns";
		public const string LegalIssues = "legal issues";
	}
} 