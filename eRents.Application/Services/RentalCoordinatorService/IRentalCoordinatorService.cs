using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;

namespace eRents.Application.Services.RentalCoordinatorService
{
    /// <summary>
    /// ✅ ENHANCED: Pure coordination interface with clean SoC
    /// Orchestrates rental operations between specialized services
    /// Replaces ISimpleRentalService with consolidated coordination responsibilities
    /// </summary>
    public interface IRentalCoordinatorService
    {
        #region Daily Rental Coordination
        /// <summary>✅ COORDINATION: Orchestrates daily booking creation through multiple services</summary>
        Task<bool> CreateDailyBookingAsync(BookingInsertRequest request);
        
        /// <summary>✅ COORDINATION: Delegates to AvailabilityService for daily rental checking</summary>
        Task<bool> IsPropertyAvailableForDailyRentalAsync(int propertyId, DateOnly startDate, DateOnly endDate);
        #endregion

        #region Monthly Rental Coordination  
        /// <summary>✅ COORDINATION: Orchestrates monthly rental request through multiple services</summary>
        Task<bool> RequestMonthlyRentalAsync(RentalRequestInsertRequest request);
        
        /// <summary>✅ COORDINATION: Delegates approval/rejection to RentalRequestService</summary>
        Task<bool> ApproveRentalRequestAsync(int requestId, bool approved, string? response = null);
        
        /// <summary>✅ COORDINATION: Retrieves pending requests for landlord</summary>
        Task<List<RentalRequestResponse>> GetPendingRequestsAsync(int landlordId);
        #endregion

        #region Availability Coordination
        /// <summary>✅ COORDINATION: Delegates to AvailabilityService for annual rental checking</summary>
        Task<bool> IsPropertyAvailableAsync(int propertyId, DateOnly startDate, DateOnly endDate);
        
        /// <summary>✅ COORDINATION: Uses conflict-based availability validation</summary>
        Task<bool> ValidateRentalAvailability(int propertyId, DateOnly startDate, DateOnly endDate);
        #endregion

        #region Contract Management Coordination
        /// <summary>✅ COORDINATION: Delegates tenant creation to RentalRequestService</summary>
        Task<bool> CreateTenantFromApprovedRequestAsync(int requestId);
        
        /// <summary>✅ COORDINATION: Retrieves expiring contracts through RentalRequestService</summary>
        Task<List<RentalRequestResponse>> GetExpiringContractsAsync(int daysAhead = 60);
        #endregion

        #region Authorization Coordination
        /// <summary>
        /// ❌ SoC VIOLATION: Authorization logic should be moved to dedicated AuthorizationService
        /// TODO: Extract to IAuthorizationService.CanUserApproveRentalRequest(userId, requestId)
        /// </summary>
        Task<bool> CanApproveRequestAsync(int requestId, int currentUserId);
        #endregion
    }
} 