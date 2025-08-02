using eRents.Features.Shared.DTOs;
using eRents.Domain.Models.Enums;
using eRents.Domain.Models.Enums;
using System.ComponentModel.DataAnnotations;

namespace eRents.Features.RentalManagement.DTOs;

/// <summary>
/// Rental request response DTO
/// </summary>
public class RentalRequestResponse
{
	public int Id { get; set; }
	public int RentalRequestId { get; set; }
	public int PropertyId { get; set; }
	public int UserId { get; set; }
	public int TenantId { get; set; }
	public int LandlordId { get; set; }
	public DateTime StartDate { get; set; }
	public DateTime EndDate { get; set; }
	public int NumberOfGuests { get; set; }
	public decimal TotalPrice { get; set; }
	public string Currency { get; set; } = "BAM";
	public RentalType RentalType { get; set; }
	public string? SpecialRequests { get; set; }
	public string? RejectionReason { get; set; }
	public DateTime? ApprovedAt { get; set; }
	public int? ApprovedBy { get; set; }
	public RentalRequestStatusEnum Status { get; set; }
	public string UserName { get; set; } = string.Empty;
	public string LandlordName { get; set; } = string.Empty;
	public string PropertyName { get; set; } = string.Empty;
	public DateTime CreatedAt { get; set; }
	public DateTime UpdatedAt { get; set; }
}

/// <summary>
/// Rental request for creating new requests
/// </summary>
public class RentalRequestRequest
{
	[Required]
	public int PropertyId { get; set; }

	[Required]
	public DateTime StartDate { get; set; }

	[Required]
	public DateTime EndDate { get; set; }

	[Required]
	[Range(1, 20)]
	public int NumberOfGuests { get; set; }

	[Required]
	[Range(0.01, 999999.99)]
	public decimal TotalPrice { get; set; }

	public string Currency { get; set; } = "BAM";

	[Required]
	public RentalType RentalType { get; set; }

	[StringLength(1000)]
	public string? SpecialRequests { get; set; }
}

/// <summary>
/// Tenant response DTO
/// </summary>
public class TenantResponse
{
	public int Id { get; set; }
	public int TenantId { get; set; }
	public int UserId { get; set; }
	public int PropertyId { get; set; }
	public DateTime LeaseStartDate { get; set; }
	public DateTime? LeaseEndDate { get; set; }
	public decimal MonthlyRent { get; set; }
	public decimal? SecurityDeposit { get; set; }
	public string Currency { get; set; } = "BAM";
	public string? LeaseTerms { get; set; }
	public string Status { get; set; } = string.Empty;
	public string UserName { get; set; } = string.Empty;
	public string LandlordName { get; set; } = string.Empty;
	public string PropertyName { get; set; } = string.Empty;
	public DateTime CreatedAt { get; set; }
	public DateTime UpdatedAt { get; set; }
}



/// <summary>
/// Rental filter request
/// </summary>
public class RentalFilterRequest : IPagedRequest
{
	public int? PropertyId { get; set; }
	public int? UserId { get; set; }
	public int? LandlordId { get; set; }
	public DateTime? StartDate { get; set; }
	public DateTime? EndDate { get; set; }
	public DateTime? ProposedStartDate { get; set; }
	public DateTime? ProposedEndDate { get; set; }
	public string? Status { get; set; }
	public RentalType? RentalType { get; set; }
	public decimal? MinPrice { get; set; }
	public decimal? MaxPrice { get; set; }
	public string? SearchTerm { get; set; }
	public string? SortBy { get; set; } = "CreatedAt";
	public string? SortOrder { get; set; } = "DESC";
	public int Page { get; set; } = 1;
	public int PageSize { get; set; } = 10;
}

/// <summary>
/// Rental paged response
/// </summary>
public class RentalPagedResponse
{
	public List<RentalRequestResponse> Items { get; set; } = new();
	public int TotalCount { get; set; }
	public int PageNumber { get; set; }
	public int PageSize { get; set; }
	public int TotalPages { get; set; }
}

/// <summary>
/// Rental approval request
/// </summary>
public class RentalApprovalRequest
{
	[StringLength(1000)]
	public string? Reason { get; set; }

	[StringLength(2000)]
	public string? Notes { get; set; }
}

#region Tenant Creation DTOs

/// <summary>
/// Request DTO for creating tenant from rental request
/// </summary>
public class CreateTenantFromRentalRequest
{
	public int RentalRequestId { get; set; }
	public int UserId { get; set; }
	public int PropertyId { get; set; }
	public DateTime StartDate { get; set; }
	public DateTime EndDate { get; set; }
	public decimal MonthlyRent { get; set; }
	public decimal? SecurityDeposit { get; set; }
	public string? SpecialTerms { get; set; }
	public string? Notes { get; set; }
}

/// <summary>
/// Response DTO for tenant creation operations
/// </summary>
public class TenantCreationResponse
{
	public int TenantId { get; set; }
	public int UserId { get; set; }
	public string? UserName { get; set; }
	public int PropertyId { get; set; }
	public string? PropertyName { get; set; }
	public DateTime StartDate { get; set; }
	public DateTime EndDate { get; set; }
	public decimal MonthlyRent { get; set; }
	public TenantStatusEnum Status { get; set; }
	public DateTime CreatedAt { get; set; }
	public bool IsSuccess { get; set; }
	public string? Message { get; set; }
}

#endregion

#region Action History DTOs

/// <summary>
/// Response DTO for rental action history operations
/// </summary>
public class RentalActionHistoryResponse
{
	public int HistoryId { get; set; }
	public int RentalRequestId { get; set; }
	public string? Action { get; set; }
	public string? Status { get; set; }
	public string? Notes { get; set; }
	public int ActionBy { get; set; }
	public string? ActionByName { get; set; }
	public DateTime ActionDate { get; set; }
	public string? Reason { get; set; }
}

#endregion
