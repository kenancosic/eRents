using eRents.Features.Shared.DTOs;
using System.ComponentModel.DataAnnotations;
using eRents.Domain.Models.Enums;

namespace eRents.Features.UserManagement.DTOs;

/// <summary>
/// Clean tenant response DTO with foreign key IDs only
/// No cross-entity data embedded - follows modular architecture principles
/// </summary>
public class TenantResponse
{
	public int TenantId { get; set; }
	public int UserId { get; set; }                  // Foreign key only
	public int? PropertyId { get; set; }             // Foreign key only
	public DateTime? LeaseStartDate { get; set; }
	public DateTime? LeaseEndDate { get; set; }
	public TenantStatusEnum TenantStatus { get; set; }
	public int? CurrentBookingId { get; set; }       // Foreign key only
	public DateTime CreatedAt { get; set; }
	public DateTime? UpdatedAt { get; set; }
}

/// <summary>
/// Tenant preference response DTO
/// </summary>
public class TenantPreferenceResponse
{
	public int PreferenceId { get; set; }
	public int UserId { get; set; }                  // Foreign key only
	public DateTime SearchStartDate { get; set; }
	public DateTime? SearchEndDate { get; set; }
	public decimal? MinPrice { get; set; }
	public decimal? MaxPrice { get; set; }
	public string City { get; set; } = string.Empty;
	public List<int> AmenityIds { get; set; } = new(); // Foreign keys only
	public string Description { get; set; } = string.Empty;
	public bool IsActive { get; set; }
	public double MatchScore { get; set; }           // For prospective tenant matching
	public DateTime CreatedAt { get; set; }
	public DateTime? UpdatedAt { get; set; }
}

/// <summary>
/// Tenant relationship response DTO
/// </summary>
public class TenantRelationshipResponse
{
	public int TenantId { get; set; }
	public int UserId { get; set; }                  // Foreign key only
	public int? PropertyId { get; set; }             // Foreign key only
	public DateTime? LeaseStartDate { get; set; }
	public DateTime? LeaseEndDate { get; set; }
	public TenantStatusEnum TenantStatus { get; set; }
	public int? CurrentBookingId { get; set; }       // Foreign key only

	// Performance metrics (computed server-side)
	public int TotalBookings { get; set; }
	public decimal TotalRevenue { get; set; }
	public decimal? AverageRating { get; set; }
	public int MaintenanceIssuesReported { get; set; }
}

/// <summary>
/// Tenant preference update request DTO
/// </summary>
public class TenantPreferenceUpdateRequest
{
	[Required]
	public DateTime SearchStartDate { get; set; }

	public DateTime? SearchEndDate { get; set; }

	[Range(0, double.MaxValue, ErrorMessage = "Min price must be non-negative")]
	public decimal? MinPrice { get; set; }

	[Range(0, double.MaxValue, ErrorMessage = "Max price must be non-negative")]
	public decimal? MaxPrice { get; set; }

	[Required]
	[StringLength(100, ErrorMessage = "City name cannot exceed 100 characters")]
	public string City { get; set; } = string.Empty;

	public List<int> AmenityIds { get; set; } = new(); // Foreign keys only

	[StringLength(1000, ErrorMessage = "Description cannot exceed 1000 characters")]
	public string Description { get; set; } = string.Empty;

	public bool IsActive { get; set; } = true;
}

/// <summary>
/// Tenant search object for filtering and pagination
/// </summary>
public class TenantSearchObject : IPagedRequest
{
	public int Page { get; set; } = 1;
	public int PageSize { get; set; } = 10;
	public string? SortBy { get; set; }
	public bool SortDescending { get; set; } = false;

	public int? UserId { get; set; }
	public int? PropertyId { get; set; }
	public TenantStatusEnum? TenantStatus { get; set; }
	public DateTime? LeaseStartAfter { get; set; }
	public DateTime? LeaseStartBefore { get; set; }
	public DateTime? LeaseEndAfter { get; set; }
	public DateTime? LeaseEndBefore { get; set; }
	public string? City { get; set; }
	public decimal? MinPrice { get; set; }
	public decimal? MaxPrice { get; set; }
	public List<int>? AmenityIds { get; set; }
	public bool? IsActive { get; set; }
}

/// <summary>
/// Tenant assignment response - maps tenant to property
/// </summary>
public class TenantPropertyAssignmentResponse
{
	public int TenantId { get; set; }
	public int UserId { get; set; }                  // Foreign key only
	public int? PropertyId { get; set; }             // Foreign key only
	public TenantStatusEnum? TenantStatus { get; set; }
	public DateTime? LeaseStartDate { get; set; }
	public DateTime? LeaseEndDate { get; set; }
}

/// <summary>
/// Tenant creation request (for creating tenant from rental request)
/// </summary>
public class TenantCreateRequest
{
	[Required]
	public int UserId { get; set; }

	[Required]
	public int PropertyId { get; set; }

	[Required]
	public int RentalRequestId { get; set; }

	[Required]
	public DateTime LeaseStartDate { get; set; }

	[Required]
	public DateTime LeaseEndDate { get; set; }

	public TenantStatusEnum TenantStatus { get; set; } = TenantStatusEnum.Active;
}