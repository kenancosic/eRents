using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;

namespace eRents.Application.Services.TenantService
{
    /// <summary>
    /// ✅ ENHANCED: Tenant service interface with documented SoC boundaries
    /// Focuses on tenant business logic - cross-entity operations marked for delegation
    /// </summary>
    public interface ITenantService
    {
        #region Current Tenants Management
        /// <summary>✅ TENANT LOGIC: Get current tenants for landlord with filtering</summary>
        Task<List<UserResponse>> GetCurrentTenantsAsync(Dictionary<string, string>? queryParams = null);
        
        /// <summary>✅ TENANT LOGIC: Get individual tenant details with relationship validation</summary>
        Task<UserResponse> GetTenantByIdAsync(int tenantId);
        #endregion
        
        #region Prospective Tenant Discovery
        /// <summary>✅ TENANT MATCHING: Get prospective tenants with ML matching scores (placeholder)</summary>
        Task<List<TenantPreferenceResponse>> GetProspectiveTenantsAsync(Dictionary<string, string>? queryParams = null);
        
        /// <summary>✅ TENANT PREFERENCES: Get tenant search preferences</summary>
        Task<TenantPreferenceResponse> GetTenantPreferencesAsync(int tenantId);
        
        /// <summary>✅ TENANT PREFERENCES: Update tenant search preferences with audit tracking</summary>
        Task<TenantPreferenceResponse> UpdateTenantPreferencesAsync(int tenantId, TenantPreferenceUpdateRequest request);
        #endregion
        
        #region Tenant Feedback Management - SoC VIOLATION
        /// <summary>❌ SoC VIOLATION: Should delegate to ReviewService.GetReviewsByRevieweeIdAsync(tenantId, ReviewType.TenantReview)</summary>
        Task<List<ReviewResponse>> GetTenantFeedbacksAsync(int tenantId);
        
        /// <summary>❌ SoC VIOLATION: Should delegate to ReviewService.CreateTenantReviewAsync(tenantId, request)</summary>
        Task<ReviewResponse> AddTenantFeedbackAsync(int tenantId, ReviewInsertRequest request);
        #endregion
        
        		#region Property Offers - FIXED: Now delegates to PropertyOfferService
		/// <summary>✅ FIXED: Delegates to PropertyOfferService.CreateOfferAsync()</summary>
		Task RecordPropertyOfferedToTenantAsync(int tenantId, int propertyId);

		/// <summary>✅ FIXED: Delegates to PropertyOfferService.GetOffersForTenantAsync()</summary>
		Task<List<PropertyOfferResponse>> GetPropertyOffersForTenantAsync(int tenantId);
        #endregion
        
        #region Tenant Relationships & Performance
        /// <summary>✅ TENANT METRICS: Get tenant relationships with performance metrics for landlord</summary>
        Task<List<TenantRelationshipResponse>> GetTenantRelationshipsForLandlordAsync();
        
        /// <summary>✅ TENANT ASSIGNMENTS: Get current property assignments for specified tenants</summary>
        Task<Dictionary<int, PropertyResponse>> GetTenantPropertyAssignmentsAsync(List<int> tenantIds);
        #endregion

        #region Annual Rental System Support
        /// <summary>❌ SoC VIOLATION: Should be moved to RentalCoordinatorService or TenantCreationService</summary>
        Task<bool> CreateTenantFromApprovedRentalRequestAsync(int rentalRequestId);
        
        /// <summary>✅ TENANT STATUS: Check if property has active tenant (valid tenant business logic)</summary>
        Task<bool> HasActiveTenantAsync(int propertyId);
        
        /// <summary>✅ TENANT FINANCES: Get current monthly rent for tenant (needs proper implementation)</summary>
        Task<decimal> GetCurrentMonthlyRentAsync(int tenantId);
        
        /// <summary>❌ SoC NOTE: Should delegate to LeaseCalculationService.GetRemainingDaysUntilExpiration()</summary>
        Task<bool> IsLeaseExpiringInDaysAsync(int tenantId, int days);
        
        /// <summary>❌ SoC NOTE: Should delegate to LeaseCalculationService.GetExpiringTenants(landlordId, daysAhead)</summary>
        Task<List<UserResponse>> GetTenantsWithExpiringLeasesAsync(int landlordId, int daysAhead);
        #endregion
    }
} 