using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;

namespace eRents.Application.Service.SimpleRentalService
{
    /// <summary>
    /// Core service for dual rental system logic as outlined in Phase 2
    /// Handles both Daily and Annual rental workflows
    /// </summary>
    public interface ISimpleRentalService
    {
        // ✅ Daily Rental Methods (existing booking flow)
        Task<bool> CreateDailyBookingAsync(BookingInsertRequest request);
        Task<bool> IsPropertyAvailableForDailyRentalAsync(int propertyId, DateOnly startDate, DateOnly endDate);

        // ✅ Annual Rental Methods (new approval workflow)
        Task<bool> RequestAnnualRentalAsync(RentalRequestInsertRequest request);
        Task<bool> ApproveRentalRequestAsync(int requestId, bool approved, string? response = null);
        Task<List<RentalRequestResponse>> GetPendingRequestsAsync(int landlordId);

        // ✅ Business Logic Validation
        Task<bool> IsPropertyAvailableAsync(int propertyId, DateOnly startDate, DateOnly endDate);
        Task<bool> ValidateLeaseDurationAsync(DateOnly startDate, DateOnly endDate);
        Task<bool> CanApproveRequestAsync(int requestId, int currentUserId);

        // ✅ Contract Management
        Task<bool> CreateTenantFromApprovedRequestAsync(int requestId);
        Task<List<RentalRequestResponse>> GetExpiringContractsAsync(int daysAhead = 60);

        // ✅ Property Status Management
        Task<bool> UpdatePropertyAvailabilityAsync(int propertyId, bool isAvailable);
        Task<string> GetPropertyRentalTypeAsync(int propertyId);
    }
} 