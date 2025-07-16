using eRents.Domain.Models;

namespace eRents.Features.Shared.Services
{
    /// <summary>
    /// Centralized service for all lease calculation logic
    /// Eliminates duplicated lease calculation logic across features
    /// </summary>
    public interface ILeaseCalculationService
    {
        #region Core Calculation Methods

        /// <summary>
        /// Calculate the lease end date for a specific tenant by ID
        /// </summary>
        Task<DateOnly?> CalculateLeaseEndDate(int tenantId);

        /// <summary>
        /// Calculate lease end date for a tenant entity
        /// </summary>
        Task<DateOnly?> CalculateLeaseEndDateForTenant(Tenant tenant);

        /// <summary>
        /// Check if a tenant's lease is expired
        /// </summary>
        Task<bool> IsLeaseExpired(int tenantId);

        /// <summary>
        /// Calculate remaining days until lease expiration
        /// </summary>
        Task<int?> GetRemainingDaysUntilExpiration(int tenantId);

        /// <summary>
        /// Get lease duration in months for a tenant
        /// </summary>
        Task<int?> GetLeaseDurationMonths(int tenantId, int propertyId);

        /// <summary>
        /// Validate if a lease duration is valid for annual rentals
        /// </summary>
        Task<bool> IsValidLeaseDuration(DateOnly startDate, DateOnly endDate);

        #endregion

        #region Tenant Query Methods

        /// <summary>
        /// Get tenants with leases expiring within the specified number of days
        /// </summary>
        Task<List<Tenant>> GetExpiringTenants(int daysAhead);

        /// <summary>
        /// Get tenants with leases expiring within the specified number of days (with navigation properties)
        /// </summary>
        Task<List<Tenant>> GetExpiringTenantsWithIncludes(int daysAhead);

        /// <summary>
        /// Get tenants with expired leases
        /// </summary>
        Task<List<Tenant>> GetExpiredTenants();

        /// <summary>
        /// Get tenants with expired leases (with navigation properties)
        /// </summary>
        Task<List<Tenant>> GetExpiredTenantsWithIncludes();

        /// <summary>
        /// Get all active tenants with their calculated lease end dates
        /// </summary>
        Task<List<TenantLeaseInfo>> GetActiveTenantsWithLeaseInfo();

        #endregion

        #region Lease Analysis Methods

        /// <summary>
        /// Get lease statistics for a property owner
        /// </summary>
        Task<LeaseStatistics> GetLeaseStatisticsAsync(int ownerId);

        /// <summary>
        /// Get tenants requiring lease renewal attention
        /// </summary>
        Task<List<TenantLeaseInfo>> GetTenantsRequiringAttention(int ownerId, int warningDays = 30);

        #endregion
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
        public string PropertyName { get; set; } = string.Empty;
        public decimal MonthlyRent { get; set; }
    }

    /// <summary>
    /// Lease statistics for property owner
    /// </summary>
    public class LeaseStatistics
    {
        public int TotalActiveLeases { get; set; }
        public int ExpiringThisMonth { get; set; }
        public int ExpiringNext30Days { get; set; }
        public int ExpiredLeases { get; set; }
        public decimal TotalMonthlyRevenue { get; set; }
        public decimal AverageLeaseDuration { get; set; }
    }
} 