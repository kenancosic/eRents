using eRents.Features.RentalManagement.DTOs;

namespace eRents.Features.RentalManagement.Services;

/// <summary>
/// Interface for RentalRequestService - handles rental request management
/// Following modular architecture principles with focused service contracts
/// </summary>
public interface IRentalRequestService
{
	#region Core CRUD Operations

	/// <summary>
	/// Get rental request by ID
	/// </summary>
	Task<RentalRequestResponse?> GetRentalRequestByIdAsync(int rentalRequestId);

	/// <summary>
	/// Create new rental request
	/// </summary>
	Task<RentalRequestResponse> CreateRentalRequestAsync(RentalRequestRequest request);

	/// <summary>
	/// Update existing rental request
	/// </summary>
	Task<RentalRequestResponse> UpdateRentalRequestAsync(int rentalRequestId, RentalRequestRequest request);

	/// <summary>
	/// Delete rental request
	/// </summary>
	Task<bool> DeleteRentalRequestAsync(int rentalRequestId);

	#endregion

	#region Query Operations

	/// <summary>
	/// Get paginated rental requests with filtering
	/// </summary>
	Task<RentalPagedResponse> GetRentalRequestsAsync(RentalFilterRequest filter);

	/// <summary>
	/// Get rental requests for specific property
	/// </summary>
	Task<List<RentalRequestResponse>> GetPropertyRentalRequestsAsync(int propertyId);

	/// <summary>
	/// Get pending rental requests requiring action
	/// </summary>
	Task<List<RentalRequestResponse>> GetPendingRentalRequestsAsync();

	/// <summary>
	/// Get expired rental requests
	/// </summary>
	Task<List<RentalRequestResponse>> GetExpiredRentalRequestsAsync();

	#endregion

	#region Approval Workflow

	/// <summary>
	/// Approve rental request
	/// </summary>
	Task<RentalRequestResponse> ApproveRentalRequestAsync(int rentalRequestId, RentalApprovalRequest approval);

	/// <summary>
	/// Reject rental request
	/// </summary>
	Task<RentalRequestResponse> RejectRentalRequestAsync(int rentalRequestId, RentalApprovalRequest rejection);

	/// <summary>
	/// Cancel rental request
	/// </summary>
	Task<RentalRequestResponse> CancelRentalRequestAsync(int rentalRequestId, string? reason = null);

	/// <summary>
	/// Check if user can approve rental request
	/// </summary>
	Task<bool> CanApproveRentalRequestAsync(int rentalRequestId, int userId);

	#endregion

	#region Validation and Authorization

	/// <summary>
	/// Check if property is available for rental request dates
	/// </summary>
	Task<bool> IsPropertyAvailableAsync(int propertyId, DateTime startDate, DateTime endDate);

	/// <summary>
	/// Validate rental request before creation
	/// </summary>
	Task<(bool IsValid, List<string> ValidationErrors)> ValidateRentalRequestAsync(RentalRequestRequest request);

	#endregion

	#region Business Logic

	/// <summary>
	/// Calculate total price for rental request
	/// </summary>
	Task<decimal> CalculateRentalPriceAsync(int propertyId, DateTime startDate, DateTime endDate, int numberOfGuests);

	#endregion
}
