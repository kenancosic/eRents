using System;
using eRents.Shared.DTO.Base;

namespace eRents.Shared.DTO.Response
{
	public class TenantRelationshipResponse : BaseResponse
	{
		// Direct tenant relationship entity fields - use exact entity field names
		public int TenantId { get; set; }
		public int UserId { get; set; } // Use UserController to fetch user details
		public int? PropertyId { get; set; } // Use PropertiesController to fetch property details
		public DateTime? LeaseStartDate { get; set; }
		public DateTime? LeaseEndDate { get; set; }
		public string? TenantStatus { get; set; } // Active, Completed, Cancelled

		// Fields from other entities - use "EntityName + FieldName" pattern
		public string? UserFirstName { get; set; }  // User's first name
		public string? UserLastName { get; set; }   // User's last name
		public string? UserEmail { get; set; }      // User's email
		public string? PropertyName { get; set; }   // Property name

		// Booking details - could be optimized further by using BookingId only
		public int? CurrentBookingId { get; set; }
		public DateTime? BookingStartDate { get; set; }
		public DateTime? BookingEndDate { get; set; }
		public string? Status { get; set; }
		public decimal? TotalPaid { get; set; }

		// Performance metrics (computed server-side for efficiency)
		public int TotalBookings { get; set; }
		public decimal TotalRevenue { get; set; }
		public double? AverageRating { get; set; }
		public int MaintenanceIssuesReported { get; set; }
		
		        // Computed properties for UI convenience (for backward compatibility)
        public string? UserFullName { get; set; }
        public string? PropertyTitle { get; set; }
	}
}