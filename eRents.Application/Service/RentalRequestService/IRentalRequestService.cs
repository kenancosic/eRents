using eRents.Application.Shared;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Shared.SearchObjects;

namespace eRents.Application.Service.RentalRequestService
{
    public interface IRentalRequestService : ICRUDService<RentalRequestResponse, RentalRequestSearchObject, RentalRequestInsertRequest, RentalRequestUpdateRequest>
    {
        // User methods (tenants/users requesting rentals)
        Task<RentalRequestResponse> RequestAnnualRentalAsync(RentalRequestInsertRequest request);
        Task<List<RentalRequestResponse>> GetMyRequestsAsync();
        Task<bool> CanRequestPropertyAsync(int propertyId);
        Task<RentalRequestResponse> WithdrawRequestAsync(int requestId);

        // Landlord methods (property owners managing requests)
        Task<List<RentalRequestResponse>> GetPendingRequestsAsync();
        Task<List<RentalRequestResponse>> GetAllRequestsForMyPropertiesAsync();
        Task<RentalRequestResponse> ApproveRequestAsync(int requestId, string? response = null);
        Task<RentalRequestResponse> RejectRequestAsync(int requestId, string? response = null);
        Task<RentalRequestResponse> RespondToRequestAsync(int requestId, RentalRequestUpdateRequest response);

        // Property-specific methods
        Task<List<RentalRequestResponse>> GetRequestsForPropertyAsync(int propertyId);
        Task<bool> HasPendingRequestsForPropertyAsync(int propertyId);
        Task<RentalRequestResponse?> GetApprovedRequestForPropertyAsync(int propertyId);

        // Business logic methods
        Task<bool> ValidateRequestBusinessRulesAsync(RentalRequestInsertRequest request);
        Task<bool> CreateTenantFromApprovedRequestAsync(int requestId);
        Task<List<RentalRequestResponse>> GetExpiringRequestsAsync(int daysAhead);
    }
} 