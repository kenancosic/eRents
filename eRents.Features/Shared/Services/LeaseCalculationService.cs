using eRents.Domain.Models;
using eRents.Domain.Shared;
using eRents.Domain.Shared.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace eRents.Features.Shared.Services
{
    /// <summary>
    /// Centralized service for all lease calculation logic using direct ERentsContext access
    /// Eliminates repository dependencies and consolidates lease business logic
    /// </summary>
    public class LeaseCalculationService : ILeaseCalculationService
    {
        private readonly ERentsContext _context;
        private readonly IUnitOfWork _unitOfWork;
        private readonly ICurrentUserService _currentUserService;
        private readonly ILogger<LeaseCalculationService> _logger;

        public LeaseCalculationService(
            ERentsContext context,
            IUnitOfWork unitOfWork,
            ICurrentUserService currentUserService,
            ILogger<LeaseCalculationService> logger)
        {
            _context = context;
            _unitOfWork = unitOfWork;
            _currentUserService = currentUserService;
            _logger = logger;
        }

        #region Core Calculation Methods

        public async Task<DateOnly?> CalculateLeaseEndDate(int tenantId)
        {
            try
            {
                var tenant = await _context.Tenants
                    .FirstOrDefaultAsync(t => t.TenantId == tenantId);

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

        public async Task<DateOnly?> CalculateLeaseEndDateForTenant(Tenant tenant)
        {
            try
            {
                // If tenant has LeaseEndDate stored, use it directly
                if (tenant.LeaseEndDate.HasValue)
                {
                    return tenant.LeaseEndDate.Value;
                }

                if (!tenant.LeaseStartDate.HasValue || !tenant.PropertyId.HasValue)
                {
                    _logger.LogWarning("Tenant {TenantId} has missing lease start date or property ID", tenant.TenantId);
                    return null;
                }

                // Find the approved rental request that corresponds to this tenant's lease
                var rentalRequest = await _context.RentalRequests
                    .Where(r => r.UserId == tenant.UserId &&
                               r.PropertyId == tenant.PropertyId.Value &&
                               r.Status == "Approved")
                    .OrderByDescending(r => r.CreatedAt)
                    .FirstOrDefaultAsync();

                if (rentalRequest == null)
                {
                    _logger.LogWarning("No approved rental request found for tenant {TenantId}", tenant.TenantId);
                    // Fallback to 12-month default for annual rentals
                    return tenant.LeaseStartDate.Value.AddMonths(12);
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

        public async Task<bool> IsLeaseExpired(int tenantId)
        {
            try
            {
                var leaseEndDate = await CalculateLeaseEndDate(tenantId);
                if (!leaseEndDate.HasValue) 
                    return false;

                var today = DateOnly.FromDateTime(DateTime.UtcNow);
                return leaseEndDate.Value < today;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error checking if lease is expired for tenant {TenantId}", tenantId);
                return false;
            }
        }

        public async Task<int?> GetRemainingDaysUntilExpiration(int tenantId)
        {
            try
            {
                var leaseEndDate = await CalculateLeaseEndDate(tenantId);
                if (!leaseEndDate.HasValue) 
                    return null;
                
                var today = DateOnly.FromDateTime(DateTime.UtcNow);
                return leaseEndDate.Value.DayNumber - today.DayNumber;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error calculating remaining days for tenant {TenantId}", tenantId);
                return null;
            }
        }

        public async Task<int?> GetLeaseDurationMonths(int tenantId, int propertyId)
        {
            try
            {
                var tenant = await _context.Tenants
                    .FirstOrDefaultAsync(t => t.TenantId == tenantId);

                if (tenant == null) 
                    return null;

                var rentalRequest = await _context.RentalRequests
                    .Where(r => r.UserId == tenant.UserId &&
                               r.PropertyId == propertyId &&
                               r.Status == "Approved")
                    .OrderByDescending(r => r.CreatedAt)
                    .FirstOrDefaultAsync();

                return rentalRequest?.LeaseDurationMonths;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting lease duration for tenant {TenantId}", tenantId);
                return null;
            }
        }

        public async Task<bool> IsValidLeaseDuration(DateOnly startDate, DateOnly endDate)
        {
            try
            {
                var days = endDate.DayNumber - startDate.DayNumber;
                return days >= 180; // At least 6 months for annual rentals
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error validating lease duration from {StartDate} to {EndDate}", startDate, endDate);
                return false;
            }
        }

        #endregion

        #region Tenant Query Methods

        public async Task<List<Tenant>> GetExpiringTenants(int daysAhead)
        {
            return await GetFilteredTenantsByLeaseStatus(daysAhead, includeNavigation: false, expiredMode: false);
        }

        public async Task<List<Tenant>> GetExpiringTenantsWithIncludes(int daysAhead)
        {
            return await GetFilteredTenantsByLeaseStatus(daysAhead, includeNavigation: true, expiredMode: false);
        }

        public async Task<List<Tenant>> GetExpiredTenants()
        {
            return await GetFilteredTenantsByLeaseStatus(0, includeNavigation: false, expiredMode: true);
        }

        public async Task<List<Tenant>> GetExpiredTenantsWithIncludes()
        {
            return await GetFilteredTenantsByLeaseStatus(0, includeNavigation: true, expiredMode: true);
        }

        public async Task<List<TenantLeaseInfo>> GetActiveTenantsWithLeaseInfo()
        {
            try
            {
                var activeTenants = await _context.Tenants
                    .Include(t => t.User)
                    .Include(t => t.Property)
                    .Where(t => t.TenantStatus == "Active" && t.LeaseStartDate.HasValue)
                    .ToListAsync();

                var leaseInfos = new List<TenantLeaseInfo>();

                foreach (var tenant in activeTenants)
                {
                    var leaseEndDate = await CalculateLeaseEndDateForTenant(tenant);
                    var remainingDays = leaseEndDate.HasValue 
                        ? leaseEndDate.Value.DayNumber - DateOnly.FromDateTime(DateTime.UtcNow).DayNumber 
                        : (int?)null;

                    var leaseDuration = await GetLeaseDurationMonths(tenant.TenantId, tenant.PropertyId ?? 0);

                    var rr = await _context.RentalRequests
                        .Where(r => r.UserId == tenant.UserId &&
                                   r.PropertyId == tenant.PropertyId.Value &&
                                   r.Status == "Approved")
                        .OrderByDescending(r => r.CreatedAt)
                        .FirstOrDefaultAsync();

                    leaseInfos.Add(new TenantLeaseInfo
                    {
                        Tenant = tenant,
                        LeaseStartDate = tenant.LeaseStartDate.Value,
        
                        LeaseDurationMonths = leaseDuration.HasValue ? leaseDuration.Value : 12,
                        RemainingDays = remainingDays,
                        IsExpired = remainingDays < 0,
                        IsExpiringSoon = remainingDays >= 0 && remainingDays <= 30,
                        PropertyName = tenant.Property?.Name ?? "Unknown Property",
                        MonthlyRent = tenant.Property?.Price ?? 0
                    });
                }

                return leaseInfos;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting active tenants with lease info");
                return new List<TenantLeaseInfo>();
            }
        }

        #endregion

        #region Lease Analysis Methods

        public async Task<LeaseStatistics> GetLeaseStatisticsAsync(int ownerId)
        {
            try
            {
                var ownerProperties = await _context.Properties
                    .Where(p => p.OwnerId == ownerId)
                    .Select(p => p.PropertyId)
                    .ToListAsync();

                var activeTenants = await _context.Tenants
                    .Include(t => t.Property)
                    .Where(t => t.TenantStatus == "Active" && 
                               t.PropertyId.HasValue &&
                               ownerProperties.Contains(t.PropertyId.Value))
                    .ToListAsync();

                var today = DateOnly.FromDateTime(DateTime.UtcNow);
                var endOfMonth = new DateOnly(today.Year, today.Month, DateTime.DaysInMonth(today.Year, today.Month));
                var next30Days = today.AddDays(30);

                var stats = new LeaseStatistics
                {
                    TotalActiveLeases = activeTenants.Count,
                    TotalMonthlyRevenue = activeTenants.Sum(t => t.Property?.Price ?? 0)
                };

                // Calculate expiring and expired leases
                foreach (var tenant in activeTenants)
                {
                    var leaseEndDate = await CalculateLeaseEndDateForTenant(tenant);
                    if (leaseEndDate.HasValue)
                    {
                        if (leaseEndDate.Value < today)
                        {
                            stats.ExpiredLeases++;
                        }
                        else if (leaseEndDate.Value <= endOfMonth)
                        {
                            stats.ExpiringThisMonth++;
                        }
                        else if (leaseEndDate.Value <= next30Days)
                        {
                            stats.ExpiringNext30Days++;
                        }
                    }
                }

                // Calculate average lease duration
                var leaseDurations = new List<int>();
                foreach (var tenant in activeTenants)
                {
                    var duration = await GetLeaseDurationMonths(tenant.TenantId, tenant.PropertyId ?? 0);
                    if (duration.HasValue)
                        leaseDurations.Add(duration.Value);
                }

                stats.AverageLeaseDuration = leaseDurations.Any() 
                    ? (decimal)leaseDurations.Average() 
                    : 0;

                return stats;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting lease statistics for owner {OwnerId}", ownerId);
                return new LeaseStatistics();
            }
        }

        public async Task<List<TenantLeaseInfo>> GetTenantsRequiringAttention(int ownerId, int warningDays = 30)
        {
            try
            {
                var ownerProperties = await _context.Properties
                    .Where(p => p.OwnerId == ownerId)
                    .Select(p => p.PropertyId)
                    .ToListAsync();

                var allLeaseInfos = await GetActiveTenantsWithLeaseInfo();
                
                return allLeaseInfos
                    .Where(info => ownerProperties.Contains(info.Tenant.PropertyId ?? 0))
                    .Where(info => info.IsExpired || 
                                  (info.RemainingDays.HasValue && info.RemainingDays.Value <= warningDays))
                    .OrderBy(info => info.RemainingDays ?? -999) // Expired first, then by remaining days
                    .ToList();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting tenants requiring attention for owner {OwnerId}", ownerId);
                return new List<TenantLeaseInfo>();
            }
        }

        #endregion

        #region Private Helper Methods

        private async Task<List<Tenant>> GetFilteredTenantsByLeaseStatus(int daysAhead, bool includeNavigation, bool expiredMode)
        {
            try
            {
                var query = _context.Tenants
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

                var today = DateOnly.FromDateTime(DateTime.UtcNow);
                var targetDate = expiredMode ? today : today.AddDays(daysAhead);

                foreach (var tenant in activeTenants)
                {
                    var leaseEndDate = await CalculateLeaseEndDateForTenant(tenant);
                    if (leaseEndDate.HasValue)
                    {
                        if (expiredMode)
                        {
                            // For expired mode, include tenants whose lease has already expired
                            if (leaseEndDate.Value < today)
                            {
                                filteredTenants.Add(tenant);
                            }
                        }
                        else
                        {
                            // For expiring mode, include tenants whose lease expires within the specified days
                            if (leaseEndDate.Value >= today && leaseEndDate.Value <= targetDate)
                            {
                                filteredTenants.Add(tenant);
                            }
                        }
                    }
                }

                return filteredTenants;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error filtering tenants by lease status");
                return new List<Tenant>();
            }
        }

        #endregion
    }
} 