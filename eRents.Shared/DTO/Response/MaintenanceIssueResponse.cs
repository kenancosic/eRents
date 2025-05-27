using System;
using System.Collections.Generic;

namespace eRents.Shared.DTO.Response
{
	public class MaintenanceIssueResponse
	{
		public int IssueId { get; set; }
		public int PropertyId { get; set; }
		public int TenantId { get; set; }
		public string Title { get; set; }
		public string Description { get; set; }
		public string Priority { get; set; }
		public string Status { get; set; }
		public DateTime DateReported { get; set; }
		public DateTime? DateResolved { get; set; }
		public List<ImageResponse> Images { get; set; }
		public string? LandlordResponse { get; set; }
		public DateTime? LandlordResponseDate { get; set; }
		public string? Category { get; set; }
		public bool RequiresInspection { get; set; }
		public bool IsTenantComplaint { get; set; }
		public decimal? Cost { get; set; }
		public string? ResolutionNotes { get; set; }
		public MaintenanceIssueResponse()
		{
			Images = new List<ImageResponse>();
		}
	}
} 