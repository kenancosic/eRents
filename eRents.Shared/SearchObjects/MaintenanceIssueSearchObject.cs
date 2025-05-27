using System;
namespace eRents.Shared.SearchObjects
{
	public class MaintenanceIssueSearchObject : BaseSearchObject
	{
		public int? PropertyId { get; set; }
		public string? Status { get; set; }
		public string? Priority { get; set; }
		public int? AssignedTo { get; set; }
		public int? ReportedBy { get; set; }
		public string? Category { get; set; }
		public bool? IsTenantComplaint { get; set; }
		public bool? RequiresInspection { get; set; }
		public DateTime? CreatedFrom { get; set; }
		public DateTime? CreatedTo { get; set; }
	}
} 