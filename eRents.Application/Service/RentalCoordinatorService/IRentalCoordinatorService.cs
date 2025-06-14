using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;

namespace eRents.Application.Service.RentalCoordinatorService
{
    /// <summary>
    /// ✅ Phase 3: Clean architectural interface for rental coordination
    /// Replaces ISimpleRentalService with focused coordination responsibilities
    /// </summary>
    public interface IRentalCoordinatorService
    {
        // ✅ Daily Rental Coordination
        Task<bool> CreateDailyBookingAsync(BookingInsertRequest request);
        Task<bool> IsPropertyAvailableForDailyRentalAsync(int propertyId, DateOnly startDate, DateOnly endDate);

        // ✅ Monthly Rental Coordination  
        Task<bool> RequestMonthlyRentalAsync(RentalRequestInsertRequest request);
        Task<bool> ApproveRentalRequestAsync(int requestId, bool approved, string? response = null);
        Task<List<RentalRequestResponse>> GetPendingRequestsAsync(int landlordId);

        // ✅ Availability Coordination
        Task<bool> IsPropertyAvailableAsync(int propertyId, DateOnly startDate, DateOnly endDate);
        Task<bool> ValidateRentalAvailability(int propertyId, DateOnly startDate, DateOnly endDate);

        // ✅ Contract Management Coordination
        Task<bool> CreateTenantFromApprovedRequestAsync(int requestId);
        Task<List<RentalRequestResponse>> GetExpiringContractsAsync(int daysAhead = 60);

        // ✅ Authorization Coordination
        Task<bool> CanApproveRequestAsync(int requestId, int currentUserId);
    }
} 