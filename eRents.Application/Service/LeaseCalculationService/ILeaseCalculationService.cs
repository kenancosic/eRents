using eRents.Domain.Models;

namespace eRents.Application.Service.LeaseCalculationService
{
    /// <summary>
    /// Centralized service for all lease calculation logic
    /// Part of Phase 2 refactoring to eliminate duplicated lease calculation logic
    /// </summary>
    public interface ILeaseCalculationService
    {
        /// <summary>
        /// Calculate the lease end date for a specific tenant
        /// Centralizes the scattered lease calculation logic
        /// </summary>
        Task<DateOnly?> CalculateLeaseEndDate(int tenantId);

        /// <summary>
        /// Calculate lease end date for a tenant entity
        /// </summary>
        Task<DateOnly?> CalculateLeaseEndDateForTenant(Tenant tenant);

        /// <summary>
        /// Get tenants with leases expiring within the specified number of days
        /// </summary>
        Task<List<Tenant>> GetExpiringTenants(int daysAhead);

        /// <summary>
        /// Get tenants with expired leases
        /// </summary>
        Task<List<Tenant>> GetExpiredTenants();

        /// <summary>
        /// Get all active tenants with their calculated lease end dates
        /// </summary>
        Task<List<TenantLeaseInfo>> GetActiveTenantsWithLeaseInfo();

        /// <summary>
        /// Check if a tenant's lease is expired
        /// </summary>
        Task<bool> IsLeaseExpired(int tenantId);

        /// <summary>
        /// Get lease duration in months for a tenant (from their rental request)
        /// </summary>
        Task<int?> GetLeaseDurationMonths(int tenantId, int propertyId);

        /// <summary>
        /// Validate if a lease duration is valid for annual rentals
        /// </summary>
        Task<bool> IsValidLeaseDuration(DateOnly startDate, DateOnly endDate);

        /// <summary>
        /// Calculate remaining days until lease expiration
        /// </summary>
        Task<int?> GetRemainingDaysUntilExpiration(int tenantId);
    }

    /// <summary>
    /// Combined tenant and lease information
    /// </summary>
    public class TenantLeaseInfo
    {
        public Tenant Tenant { get; set; } = null!;
        public DateOnly LeaseStartDate { get; set; }
        public DateOnly? LeaseEndDate { get; set; }
        public int LeaseDurationMonths { get; set; }
        public int? RemainingDays { get; set; }
        public bool IsExpired { get; set; }
        public bool IsExpiringSoon { get; set; }
    }
} 