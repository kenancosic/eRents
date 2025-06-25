using eRents.Domain.Models;
using eRents.Domain.Repositories;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace eRents.Application.Services.LeaseCalculationService
{
    /// <summary>
    /// Centralized service for all lease calculation logic
    /// Focuses purely on business logic calculations while delegating data access to repositories
    /// Part of Phase 2 refactoring to eliminate duplicated lease calculation logic
    /// </summary>
    public class LeaseCalculationService : ILeaseCalculationService
    {
        #region Dependencies
        private readonly ITenantRepository _tenantRepository;
        private readonly IRentalRequestRepository _rentalRequestRepository;
        private readonly ILogger<LeaseCalculationService> _logger;

        public LeaseCalculationService(
            ITenantRepository tenantRepository,
            IRentalRequestRepository rentalRequestRepository,
            ILogger<LeaseCalculationService> logger)
        {
            _tenantRepository = tenantRepository;
            _rentalRequestRepository = rentalRequestRepository;
            _logger = logger;
        }
        #endregion

        #region Core Calculation Methods

        /// <summary>
        /// Calculate the lease end date for a specific tenant
        /// Centralizes the scattered lease calculation logic from PropertyRepository.GetLeaseEndDateForTenant
        /// </summary>
        public async Task<DateOnly?> CalculateLeaseEndDate(int tenantId)
        {
            try
            {
                var tenant = await _tenantRepository.GetByIdAsync(tenantId);
                if (tenant == null)
                {
                    _logger.LogWarning("Tenant {TenantId} not found", tenantId);
                    return null;
                }

                return await CalculateLeaseEndDateForTenant(tenant);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error calculating lease end date for tenant {TenantId}", tenantId);
                return null;
            }
        }

        /// <summary>
        /// Calculate lease end date for a tenant entity
        /// Consolidates PropertyRepository.GetLeaseEndDateForTenant method
        /// </summary>
        public async Task<DateOnly?> CalculateLeaseEndDateForTenant(Tenant tenant)
        {
            try
            {
                if (!tenant.LeaseStartDate.HasValue || !tenant.PropertyId.HasValue)
                {
                    _logger.LogWarning("Tenant {TenantId} has missing lease start date or property ID", tenant.TenantId);
                    return null;
                }

                // Find the approved rental request that corresponds to this tenant's lease
                var rentalRequest = await _rentalRequestRepository.GetQueryable()
                    .Where(r => r.UserId == tenant.UserId &&
                               r.PropertyId == tenant.PropertyId.Value &&
                               r.Status == "Approved")
                    .OrderByDescending(r => r.RequestDate)
                    .FirstOrDefaultAsync();

                if (rentalRequest == null)
                {
                    _logger.LogWarning("No approved rental request found for tenant {TenantId}", tenant.TenantId);
                    return null;
                }

                var leaseEndDate = tenant.LeaseStartDate.Value.AddMonths(rentalRequest.LeaseDurationMonths);
                
                _logger.LogDebug("Calculated lease end date for tenant {TenantId}: {LeaseEndDate} (Duration: {Duration} months)", 
                    tenant.TenantId, leaseEndDate, rentalRequest.LeaseDurationMonths);
                
                return leaseEndDate;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error calculating lease end date for tenant {TenantId}", tenant.TenantId);
                return null;
            }
        }

        /// <summary>
        /// Validate if a lease duration is valid for annual rentals
        /// Consolidates SimpleRentalService.IsValidLeaseDuration logic
        /// </summary>
        public async Task<bool> IsValidLeaseDuration(DateOnly startDate, DateOnly endDate)
        {
            var days = endDate.DayNumber - startDate.DayNumber;
            return days >= 180; // At least 6 months
        }

        /// <summary>
        /// Check if a tenant's lease is expired
        /// </summary>
        public async Task<bool> IsLeaseExpired(int tenantId)
        {
            var leaseEndDate = await CalculateLeaseEndDate(tenantId);
            return leaseEndDate < DateOnly.FromDateTime(DateTime.UtcNow);
        }

        /// <summary>
        /// Calculate remaining days until lease expiration
        /// </summary>
        public async Task<int?> GetRemainingDaysUntilExpiration(int tenantId)
        {
            var leaseEndDate = await CalculateLeaseEndDate(tenantId);
            if (!leaseEndDate.HasValue) return null;
            
            var today = DateOnly.FromDateTime(DateTime.UtcNow);
            return leaseEndDate.Value.DayNumber - today.DayNumber;
        }

        /// <summary>
        /// Get lease duration in months for a tenant (from their rental request)
        /// </summary>
        public async Task<int?> GetLeaseDurationMonths(int tenantId, int propertyId)
        {
            try
            {
                var tenant = await _tenantRepository.GetByIdAsync(tenantId);
                if (tenant == null) return null;

                var rentalRequest = await _rentalRequestRepository.GetQueryable()
                    .Where(r => r.UserId == tenant.UserId &&
                               r.PropertyId == propertyId &&
                               r.Status == "Approved")
                    .OrderByDescending(r => r.RequestDate)
                    .FirstOrDefaultAsync();

                return rentalRequest?.LeaseDurationMonths;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting lease duration for tenant {TenantId}", tenantId);
                return null;
            }
        }

        #endregion

        #region Tenant Query Methods - Delegated to Repository

        /// <summary>
        /// Get tenants with leases expiring within the specified number of days
        /// Delegates data filtering to repository, focuses on calculation logic
        /// </summary>
        public async Task<List<Tenant>> GetExpiringTenants(int daysAhead)
        {
            return await GetFilteredTenantsByLeaseStatus(daysAhead, includeNavigation: false, expiredMode: false);
        }

        /// <summary>
        /// Get tenants with leases expiring within the specified number of days (with navigation properties for notifications)
        /// Eliminates double-query pattern in ContractExpirationService
        /// </summary>
        public async Task<List<Tenant>> GetExpiringTenantsWithIncludes(int daysAhead)
        {
            return await GetFilteredTenantsByLeaseStatus(daysAhead, includeNavigation: true, expiredMode: false);
        }

        /// <summary>
        /// Get tenants with expired leases
        /// </summary>
        public async Task<List<Tenant>> GetExpiredTenants()
        {
            return await GetFilteredTenantsByLeaseStatus(0, includeNavigation: false, expiredMode: true);
        }

        /// <summary>
        /// Get tenants with expired leases (with navigation properties for processing)
        /// Eliminates double-query pattern in ContractExpirationService
        /// </summary>
        public async Task<List<Tenant>> GetExpiredTenantsWithIncludes()
        {
            return await GetFilteredTenantsByLeaseStatus(0, includeNavigation: true, expiredMode: true);
        }

        /// <summary>
        /// Get all active tenants with their calculated lease end dates
        /// </summary>
        public async Task<List<TenantLeaseInfo>> GetActiveTenantsWithLeaseInfo()
        {
            try
            {
                var today = DateOnly.FromDateTime(DateTime.UtcNow);
                var activeTenants = await _tenantRepository.GetQueryable()
                    .Where(t => t.TenantStatus == "Active" && t.LeaseStartDate.HasValue)
                    .ToListAsync();

                var result = new List<TenantLeaseInfo>();

                foreach (var tenant in activeTenants)
                {
                    var leaseEndDate = await CalculateLeaseEndDateForTenant(tenant);
                    var leaseDuration = await GetLeaseDurationMonths(tenant.TenantId, tenant.PropertyId ?? 0);

                    var info = new TenantLeaseInfo
                    {
                        Tenant = tenant,
                        LeaseStartDate = tenant.LeaseStartDate!.Value,
                        LeaseEndDate = leaseEndDate,
                        LeaseDurationMonths = leaseDuration ?? 12,
                        RemainingDays = leaseEndDate?.DayNumber - today.DayNumber,
                        IsExpired = leaseEndDate < today,
                        IsExpiringSoon = leaseEndDate >= today && leaseEndDate <= today.AddDays(30)
                    };

                    result.Add(info);
                }

                return result;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting active tenants with lease info");
                return new List<TenantLeaseInfo>();
            }
        }

        #endregion

        #region Private Helper Methods

        /// <summary>
        /// Consolidated method to filter tenants by lease status
        /// Eliminates redundancy between expiring/expired methods
        /// </summary>
        private async Task<List<Tenant>> GetFilteredTenantsByLeaseStatus(int daysAhead, bool includeNavigation, bool expiredMode)
        {
            try
            {
                var today = DateOnly.FromDateTime(DateTime.UtcNow);
                var targetDate = expiredMode ? today : today.AddDays(daysAhead);

                // Build query with conditional includes
                var query = _tenantRepository.GetQueryable()
                    .Where(t => t.TenantStatus == "Active" && t.LeaseStartDate.HasValue);

                if (includeNavigation)
                {
                    query = query
                        .Include(t => t.User)
                        .Include(t => t.Property)
                            .ThenInclude(p => p.Owner);
                }

                var activeTenants = await query.ToListAsync();
                var filteredTenants = new List<Tenant>();

                foreach (var tenant in activeTenants)
                {
                    var leaseEndDate = await CalculateLeaseEndDateForTenant(tenant);
                    if (!leaseEndDate.HasValue) continue;

                    bool matchesCriteria = expiredMode 
                        ? leaseEndDate.Value < today 
                        : leaseEndDate.Value >= today && leaseEndDate.Value <= targetDate;

                    if (matchesCriteria)
                    {
                        filteredTenants.Add(tenant);
                    }
                }

                var logMessage = expiredMode ? "expired leases" : $"leases expiring within {daysAhead} days";
                var includeMessage = includeNavigation ? " (with includes)" : "";
                
                _logger.LogInformation("Found {Count} tenants with {LogMessage}{IncludeMessage}", 
                    filteredTenants.Count, logMessage, includeMessage);

                return filteredTenants;
            }
            catch (Exception ex)
            {
                var errorContext = expiredMode ? "expired tenants" : $"expiring tenants within {daysAhead} days";
                _logger.LogError(ex, "Error getting {ErrorContext}", errorContext);
                return new List<Tenant>();
            }
        }

        #endregion
    }
} 