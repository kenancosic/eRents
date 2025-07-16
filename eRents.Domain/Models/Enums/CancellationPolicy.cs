namespace eRents.Domain.Models.Enums
{
	public enum CancellationPolicy
	{
		/// <summary>
		/// Standard cancellation policy with timeline-based refunds
		/// </summary>
		Standard = 0,

		/// <summary>
		/// Flexible cancellation policy with more lenient refunds
		/// </summary>
		Flexible = 1,

		/// <summary>
		/// Emergency cancellation policy (full refund, no processing fees)
		/// Used for property damage, maintenance issues, force majeure
		/// </summary>
		Emergency = 2,

		/// <summary>
		/// Strict cancellation policy with limited refunds
		/// </summary>
		Strict = 3
	}
} 