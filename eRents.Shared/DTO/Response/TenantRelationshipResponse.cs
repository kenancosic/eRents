using System;
using eRents.Shared.DTO.Base;

namespace eRents.Shared.DTO.Response
{
	public class TenantRelationshipResponse : BaseResponse
	{
		public int TenantId { get; set; }
		public int UserId { get; set; } // Use UserController to fetch user details
		public int? PropertyId { get; set; } // Use PropertiesController to fetch property details
		public DateTime? LeaseStartDate { get; set; }
		public DateTime? LeaseEndDate { get; set; }
		public string? TenantStatus { get; set; } // Active, Completed, Cancelled

		// Essential display fields (small data)
		public string UserFullName { get; set; } = null!; // Keep for list display
		public string UserEmail { get; set; } = null!; // Keep for contact
		public string? PropertyTitle { get; set; } // Keep for list display

		// Booking details - could be optimized further by using BookingId only
		public int? CurrentBookingId { get; set; }
		public DateTime? BookingStartDate { get; set; }
		public DateTime? BookingEndDate { get; set; }
		public string? BookingStatus { get; set; }
		public decimal? TotalPaid { get; set; }

		// Performance metrics (computed server-side for efficiency)
		public int TotalBookings { get; set; }
		public decimal TotalRevenue { get; set; }
		public double? AverageRating { get; set; }
		public int MaintenanceIssuesReported { get; set; }
	}
}