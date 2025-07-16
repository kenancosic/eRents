using eRents.Features.TenantManagement.DTOs;
using eRents.Features.Shared.DTOs;

namespace eRents.Features.TenantManagement.Services;

/// <summary>
/// TenantManagement service interface following modular architecture
/// Clean separation with property boundaries and minimal cross-entity operations
/// SoC violations from old service addressed through proper delegation
/// </summary>
public interface ITenantService
{
    #region Current Tenants Management
    
    /// <summary>
    /// Get current tenants for landlord with filtering
    /// </summary>
    Task<PagedResponse<TenantResponse>> GetCurrentTenantsAsync(TenantSearchObject search);
    
    /// <summary>
    /// Get individual tenant details with relationship validation
    /// </summary>
    Task<TenantResponse?> GetTenantByIdAsync(int tenantId);
    
    #endregion
    
    #region Prospective Tenant Discovery
    
    /// <summary>
    /// Get prospective tenants with match scoring
    /// </summary>
    Task<PagedResponse<TenantPreferenceResponse>> GetProspectiveTenantsAsync(TenantSearchObject search);
    
    /// <summary>
    /// Get tenant search preferences
    /// </summary>
    Task<TenantPreferenceResponse?> GetTenantPreferencesAsync(int tenantId);
    
    /// <summary>
    /// Update tenant search preferences with audit tracking
    /// </summary>
    Task<TenantPreferenceResponse> UpdateTenantPreferencesAsync(int tenantId, TenantPreferenceUpdateRequest request);
    
    #endregion
    
    #region Tenant Relationships & Performance
    
    /// <summary>
    /// Get tenant relationships with performance metrics for landlord
    /// </summary>
    Task<List<TenantRelationshipResponse>> GetTenantRelationshipsForLandlordAsync();
    
    /// <summary>
    /// Get current property assignments for specified tenants
    /// </summary>
    Task<Dictionary<int, TenantPropertyAssignmentResponse>> GetTenantPropertyAssignmentsAsync(List<int> tenantIds);
    
    #endregion
    
    #region Tenant Status Operations
    
    /// <summary>
    /// Check if property has active tenant
    /// </summary>
    Task<bool> HasActiveTenantAsync(int propertyId);
    
    /// <summary>
    /// Get current monthly rent for tenant
    /// </summary>
    Task<decimal> GetCurrentMonthlyRentAsync(int tenantId);
    
    /// <summary>
    /// Create tenant from approved rental request (SoC: should be moved to TenantCreationService)
    /// </summary>
    Task<TenantResponse> CreateTenantFromApprovedRentalRequestAsync(TenantCreateRequest request);
    
    #endregion
    
    #region Lease Status Checks (delegates to LeaseCalculationService)
    
    /// <summary>
    /// Check if lease is expiring in specified days (delegates to LeaseCalculationService)
    /// </summary>
    Task<bool> IsLeaseExpiringInDaysAsync(int tenantId, int days);
    
    /// <summary>
    /// Get tenants with expiring leases (delegates to LeaseCalculationService)
    /// </summary>
    Task<List<TenantResponse>> GetTenantsWithExpiringLeasesAsync(int landlordId, int daysAhead);
    
    #endregion
} 