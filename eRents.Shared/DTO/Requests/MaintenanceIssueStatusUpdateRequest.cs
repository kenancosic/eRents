using System;

namespace eRents.Shared.DTO.Requests
{
	public class MaintenanceIssueStatusUpdateRequest
	{
		public string Status { get; set; }
		public string? ResolutionNotes { get; set; }
		public decimal? Cost { get; set; }
		public DateTime? ResolvedAt { get; set; }
	}
}