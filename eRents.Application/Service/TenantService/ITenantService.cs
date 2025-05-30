using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;

namespace eRents.Application.Service.TenantService
{
    public interface ITenantService
    {
        // Current Tenants Management
        Task<List<UserResponseDto>> GetCurrentTenantsAsync(Dictionary<string, string>? queryParams = null);
        Task<UserResponseDto> GetTenantByIdAsync(int tenantId);
        
        // Prospective Tenant Discovery
        Task<List<TenantPreferenceResponseDto>> GetProspectiveTenantsAsync(Dictionary<string, string>? queryParams = null);
        Task<TenantPreferenceResponseDto> GetTenantPreferencesAsync(int tenantId);
        Task<TenantPreferenceResponseDto> UpdateTenantPreferencesAsync(int tenantId, UpdateTenantPreferenceRequestDto request);
        
        // Tenant Feedback Management
        Task<List<ReviewResponseDto>> GetTenantFeedbacksAsync(int tenantId);
        Task<ReviewResponseDto> AddTenantFeedbackAsync(int tenantId, CreateReviewRequestDto request);
        
        // Property Offers to Tenants
        Task RecordPropertyOfferedToTenantAsync(int tenantId, int propertyId);
        Task<List<PropertyOfferResponseDto>> GetPropertyOffersForTenantAsync(int tenantId);
        
        // Tenant Relationships
        Task<List<TenantRelationshipDto>> GetTenantRelationshipsForLandlordAsync();
        Task<Dictionary<int, PropertyResponseDto>> GetTenantPropertyAssignmentsAsync(List<int> tenantIds);
    }
} 