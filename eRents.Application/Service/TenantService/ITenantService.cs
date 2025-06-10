using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;

namespace eRents.Application.Service.TenantService
{
    public interface ITenantService
    {
        // Current Tenants Management
        Task<List<UserResponse>> GetCurrentTenantsAsync(Dictionary<string, string>? queryParams = null);
        Task<UserResponse> GetTenantByIdAsync(int tenantId);
        
        // Prospective Tenant Discovery
        Task<List<TenantPreferenceResponse>> GetProspectiveTenantsAsync(Dictionary<string, string>? queryParams = null);
        Task<TenantPreferenceResponse> GetTenantPreferencesAsync(int tenantId);
        Task<TenantPreferenceResponse> UpdateTenantPreferencesAsync(int tenantId, TenantPreferenceUpdateRequest request);
        
        // Tenant Feedback Management
        Task<List<ReviewResponse>> GetTenantFeedbacksAsync(int tenantId);
        Task<ReviewResponse> AddTenantFeedbackAsync(int tenantId, ReviewInsertRequest request);
        
        // Property Offers to Tenants
        Task RecordPropertyOfferedToTenantAsync(int tenantId, int propertyId);
        Task<List<PropertyOfferResponse>> GetPropertyOffersForTenantAsync(int tenantId);
        
        // Tenant Relationships
        Task<List<TenantRelationshipResponse>> GetTenantRelationshipsForLandlordAsync();
        Task<Dictionary<int, PropertyResponse>> GetTenantPropertyAssignmentsAsync(List<int> tenantIds);

        // 🆕 NEW: Annual Rental System Support
        Task<bool> CreateTenantFromApprovedRentalRequestAsync(int rentalRequestId);
        Task<bool> HasActiveTenantAsync(int propertyId);
        Task<DateTime?> GetLeaseEndDateAsync(int tenantId);
        Task<decimal> GetCurrentMonthlyRentAsync(int tenantId);
        Task<bool> IsLeaseExpiringInDaysAsync(int tenantId, int days);
        Task<List<UserResponse>> GetTenantsWithExpiringLeasesAsync(int landlordId, int daysAhead);
    }
} 