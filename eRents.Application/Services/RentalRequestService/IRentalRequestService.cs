using eRents.Application.Shared;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Shared.SearchObjects;

namespace eRents.Application.Services.RentalRequestService
{
    /// <summary>
    /// ✅ ENHANCED: Rental request service interface with documented SoC boundaries
    /// Handles rental request lifecycle and coordination
    /// </summary>
    public interface IRentalRequestService : ICRUDService<RentalRequestResponse, RentalRequestSearchObject, RentalRequestInsertRequest, RentalRequestUpdateRequest>
    {
        #region User Methods (Tenant/User Requesting Rentals)
        /// <summary>✅ BUSINESS LOGIC: Creates annual rental request with validation</summary>
        Task<RentalRequestResponse> RequestAnnualRentalAsync(RentalRequestInsertRequest request);
        
        /// <summary>✅ DATA ACCESS: Retrieves user's own rental requests</summary>
        Task<List<RentalRequestResponse>> GetMyRequestsAsync();
        
        /// <summary>✅ CONSOLIDATED: Uses repository method for comprehensive availability check</summary>
        Task<bool> CanRequestPropertyAsync(int propertyId);
        
        /// <summary>✅ BUSINESS LOGIC: Withdraws pending rental request with authorization</summary>
        Task<RentalRequestResponse> WithdrawRequestAsync(int requestId);
        #endregion

        #region Landlord Methods (Property Owner Managing Requests)
        /// <summary>✅ DATA ACCESS: Retrieves pending requests for landlord's properties</summary>
        Task<List<RentalRequestResponse>> GetPendingRequestsAsync();
        
        /// <summary>✅ DATA ACCESS: Retrieves all requests for landlord's properties</summary>
        Task<List<RentalRequestResponse>> GetAllRequestsForMyPropertiesAsync();
        
        /// <summary>✅ BUSINESS LOGIC: Approves rental request with tenant creation</summary>
        Task<RentalRequestResponse> ApproveRequestAsync(int requestId, string? response = null);
        
        /// <summary>✅ BUSINESS LOGIC: Rejects rental request</summary>
        Task<RentalRequestResponse> RejectRequestAsync(int requestId, string? response = null);
        
        /// <summary>✅ BUSINESS LOGIC: Updates rental request with landlord response</summary>
        Task<RentalRequestResponse> RespondToRequestAsync(int requestId, RentalRequestUpdateRequest response);
        #endregion

        #region Property-Specific Methods
        /// <summary>✅ DATA ACCESS: Retrieves all requests for specific property</summary>
        Task<List<RentalRequestResponse>> GetRequestsForPropertyAsync(int propertyId);
        
        /// <summary>✅ DATA ACCESS: Checks if property has pending requests</summary>
        Task<bool> HasPendingRequestsForPropertyAsync(int propertyId);
        
        /// <summary>✅ DATA ACCESS: Gets approved request for property</summary>
        Task<RentalRequestResponse?> GetApprovedRequestForPropertyAsync(int propertyId);
        #endregion

        #region Business Logic Methods
        /// <summary>✅ BUSINESS LOGIC: Validates rental request business rules</summary>
        Task<bool> ValidateRequestBusinessRulesAsync(RentalRequestInsertRequest request);
        
        /// <summary>
        /// ❌ SoC VIOLATION: Cross-entity operation creating Tenant and updating Property
        /// TODO: Move to TenantService.CreateFromApprovedRentalRequest() or TenantCreationService
        /// </summary>
        Task<bool> CreateTenantFromApprovedRequestAsync(int requestId);
        
        /// <summary>✅ DATA ACCESS: Gets requests approaching expiration</summary>
        Task<List<RentalRequestResponse>> GetExpiringRequestsAsync(int daysAhead);
        #endregion
    }
} 