using eRents.Domain.Models;
using eRents.Domain.Shared;
using eRents.Domain.Shared.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace eRents.Features.Shared.Services
{
    /// <summary>
    /// Contract expiration monitoring service using direct ERentsContext access
    /// Integrates with NotificationService and LeaseCalculationService for complete contract lifecycle management
    /// </summary>
    public class ContractExpirationService : IContractExpirationService
    {
        private readonly ERentsContext _context;
        private readonly IUnitOfWork _unitOfWork;
        private readonly ICurrentUserService _currentUserService;
        private readonly ILogger<ContractExpirationService> _logger;
        private readonly INotificationService _notificationService;
        private readonly ILeaseCalculationService _leaseCalculationService;

        public ContractExpirationService(
            ERentsContext context,
            IUnitOfWork unitOfWork,
            ICurrentUserService currentUserService,
            ILogger<ContractExpirationService> logger,
            INotificationService notificationService,
            ILeaseCalculationService leaseCalculationService)
        {
            _context = context;
            _unitOfWork = unitOfWork;
            _currentUserService = currentUserService;
            _logger = logger;
            _notificationService = notificationService;
            _leaseCalculationService = leaseCalculationService;
        }

        #region Contract Monitoring

        public async Task CheckContractsExpiringAsync(int daysAhead = 60)
        {
            try
            {
                _logger.LogInformation("Checking for contracts expiring in {DaysAhead} days", daysAhead);

                // Use centralized LeaseCalculationService for consistency
                var expiringTenants = await _leaseCalculationService.GetExpiringTenantsWithIncludes(daysAhead);

                foreach (var tenant in expiringTenants)
                {
                    try
                    {
                        var leaseEndDate = await _leaseCalculationService.CalculateLeaseEndDateForTenant(tenant);
                        if (!leaseEndDate.HasValue) continue;

                        var daysUntilExpiration = leaseEndDate.Value.DayNumber - DateOnly.FromDateTime(DateTime.UtcNow).DayNumber;

                        // Notify tenant
                        await _notificationService.CreateNotificationAsync(
                            tenant.UserId,
                            "Contract Expiring Soon",
                            $"Your lease for {tenant.Property?.Name ?? "your property"} expires in {daysUntilExpiration} days. Please contact your landlord to discuss renewal.",
                            "contract_expiring",
                            tenant.PropertyId);

                        // Notify landlord
                        if (tenant.Property?.OwnerId != null)
                        {
                            await _notificationService.CreateNotificationAsync(
                                tenant.Property.OwnerId,
                                "Tenant Contract Expiring",
                                $"Tenant contract for {tenant.Property.Name} expires in {daysUntilExpiration} days. Please discuss renewal with tenant.",
                                "contract_expiring",
                                tenant.PropertyId);
                        }

                        _logger.LogInformation("Sent expiring contract notifications for tenant {TenantId}, property {PropertyId}", 
                            tenant.TenantId, tenant.PropertyId);
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "Failed to process expiring contract for tenant {TenantId}", tenant.TenantId);
                    }
                }

                _logger.LogInformation("Processed {Count} expiring contracts", expiringTenants.Count);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error checking contracts expiring in {DaysAhead} days", daysAhead);
                throw;
            }
        }

        public async Task ProcessExpiredContractsAsync()
        {
            try
            {
                _logger.LogInformation("Processing expired contracts");

                // Use centralized LeaseCalculationService for consistency
                var expiredTenants = await _leaseCalculationService.GetExpiredTenantsWithIncludes();

                foreach (var tenant in expiredTenants)
                {
                    try
                    {
                        // Mark property as available for rental
                        if (tenant.Property != null)
                        {
                            tenant.Property.Status = "Available";
                            tenant.Property.UpdatedAt = DateTime.UtcNow;
                            await _unitOfWork.SaveChangesAsync();
                        }

                        var leaseEndDate = await _leaseCalculationService.CalculateLeaseEndDateForTenant(tenant);
                        var daysOverdue = leaseEndDate.HasValue 
                            ? DateOnly.FromDateTime(DateTime.UtcNow).DayNumber - leaseEndDate.Value.DayNumber 
                            : 0;

                        // Notify tenant about contract expiration
                        await _notificationService.CreateNotificationAsync(
                            tenant.UserId,
                            "Contract Expired",
                            $"Your lease for {tenant.Property?.Name ?? "your property"} has expired {daysOverdue} days ago. The property is now available for new rentals, but you can still request an extension.",
                            "contract_expired",
                            tenant.PropertyId);

                        // Notify landlord
                        if (tenant.Property?.OwnerId != null)
                        {
                            await _notificationService.CreateNotificationAsync(
                                tenant.Property.OwnerId,
                                "Contract Expired",
                                $"The tenant contract for {tenant.Property.Name} has expired {daysOverdue} days ago. The property is now available for new bookings.",
                                "contract_expired",
                                tenant.PropertyId);
                        }

                        _logger.LogInformation("Processed expired contract for tenant {TenantId}, property {PropertyId}", 
                            tenant.TenantId, tenant.PropertyId);
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "Failed to process expired contract for tenant {TenantId}", tenant.TenantId);
                    }
                }

                _logger.LogInformation("Processed {Count} expired contracts", expiredTenants.Count);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error processing expired contracts");
                throw;
            }
        }

        public async Task RunContractExpirationCheckAsync()
        {
            try
            {
                _logger.LogInformation("Starting complete contract expiration check");

                await CheckContractsExpiringAsync(60); // 60-day warning
                await CheckContractsExpiringAsync(30); // 30-day warning
                await CheckContractsExpiringAsync(7);  // 7-day warning
                await ProcessExpiredContractsAsync();

                _logger.LogInformation("Completed contract expiration check");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error running contract expiration check");
                throw;
            }
        }

        #endregion

        #region Contract Analysis

        public async Task<ContractExpirationSummary> GetExpirationSummaryAsync()
        {
            try
            {
                var today = DateOnly.FromDateTime(DateTime.UtcNow);
                var in30Days = today.AddDays(30);
                var in60Days = today.AddDays(60);

                var activeLeaseInfos = await _leaseCalculationService.GetActiveTenantsWithLeaseInfo();

                var summary = new ContractExpirationSummary
                {
                    TotalActiveContracts = activeLeaseInfos.Count,
                    ExpiredContractsToday = activeLeaseInfos.Count(info => info.IsExpired),
                    LastProcessedDate = DateTime.UtcNow
                };

                // Count expiring contracts
                foreach (var leaseInfo in activeLeaseInfos.Where(info => !info.IsExpired))
                {
                    if (leaseInfo.LeaseEndDate.HasValue)
                    {
                        if (leaseInfo.LeaseEndDate.Value <= in30Days)
                        {
                            summary.ContractsExpiringIn30Days++;
                        }
                        else if (leaseInfo.LeaseEndDate.Value <= in60Days)
                        {
                            summary.ContractsExpiringIn60Days++;
                        }
                    }
                }

                // Get total expired contracts (including previously processed)
                var allExpiredTenants = await _leaseCalculationService.GetExpiredTenants();
                summary.TotalExpiredContracts = allExpiredTenants.Count;

                return summary;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting expiration summary");
                return new ContractExpirationSummary();
            }
        }

        public async Task<List<ExpiringContractInfo>> GetExpiringContractsForOwnerAsync(int ownerId, int daysAhead = 60)
        {
            try
            {
                var ownerProperties = await _context.Properties
                    .Where(p => p.OwnerId == ownerId)
                    .Select(p => p.PropertyId)
                    .ToListAsync();

                var expiringTenants = await _leaseCalculationService.GetExpiringTenantsWithIncludes(daysAhead);
                var ownerExpiringTenants = expiringTenants
                    .Where(t => t.PropertyId.HasValue && ownerProperties.Contains(t.PropertyId.Value))
                    .ToList();

                var result = new List<ExpiringContractInfo>();

                foreach (var tenant in ownerExpiringTenants)
                {
                    var leaseEndDate = await _leaseCalculationService.CalculateLeaseEndDateForTenant(tenant);
                    if (!leaseEndDate.HasValue) continue;

                    var daysUntilExpiration = leaseEndDate.Value.DayNumber - DateOnly.FromDateTime(DateTime.UtcNow).DayNumber;

                    result.Add(new ExpiringContractInfo
                    {
                        TenantId = tenant.TenantId,
                        PropertyId = tenant.PropertyId ?? 0,
                        PropertyName = tenant.Property?.Name ?? "Unknown Property",
                        TenantName = $"{tenant.User?.FirstName} {tenant.User?.LastName}".Trim(),
                        LeaseEndDate = leaseEndDate.Value,
                        DaysUntilExpiration = daysUntilExpiration,
                        MonthlyRent = tenant.Property?.Price ?? 0,
                        NotificationSent = false // TODO: Track notification status
                    });
                }

                return result.OrderBy(r => r.DaysUntilExpiration).ToList();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting expiring contracts for owner {OwnerId}", ownerId);
                return new List<ExpiringContractInfo>();
            }
        }

        public async Task<List<ExpiredContractInfo>> GetExpiredContractsForOwnerAsync(int ownerId)
        {
            try
            {
                var ownerProperties = await _context.Properties
                    .Where(p => p.OwnerId == ownerId)
                    .Select(p => p.PropertyId)
                    .ToListAsync();

                var expiredTenants = await _leaseCalculationService.GetExpiredTenantsWithIncludes();
                var ownerExpiredTenants = expiredTenants
                    .Where(t => t.PropertyId.HasValue && ownerProperties.Contains(t.PropertyId.Value))
                    .ToList();

                var result = new List<ExpiredContractInfo>();

                foreach (var tenant in ownerExpiredTenants)
                {
                    var leaseEndDate = await _leaseCalculationService.CalculateLeaseEndDateForTenant(tenant);
                    if (!leaseEndDate.HasValue) continue;

                    var daysOverdue = DateOnly.FromDateTime(DateTime.UtcNow).DayNumber - leaseEndDate.Value.DayNumber;

                    result.Add(new ExpiredContractInfo
                    {
                        TenantId = tenant.TenantId,
                        PropertyId = tenant.PropertyId ?? 0,
                        PropertyName = tenant.Property?.Name ?? "Unknown Property",
                        TenantName = $"{tenant.User?.FirstName} {tenant.User?.LastName}".Trim(),
                        LeaseEndDate = leaseEndDate.Value,
                        DaysOverdue = daysOverdue,
                        MonthlyRent = tenant.Property?.Price ?? 0,
                        PropertyMarkedAvailable = tenant.Property?.Status == "Available",
                        NotificationSent = false // TODO: Track notification status
                    });
                }

                return result.OrderByDescending(r => r.DaysOverdue).ToList();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting expired contracts for owner {OwnerId}", ownerId);
                return new List<ExpiredContractInfo>();
            }
        }

        #endregion

        #region Manual Processing

        public async Task ProcessSpecificContractExpirationAsync(int tenantId)
        {
            try
            {
                var tenant = await _context.Tenants
                    .Include(t => t.User)
                    .Include(t => t.Property)
                    .ThenInclude(p => p.Owner)
                    .FirstOrDefaultAsync(t => t.TenantId == tenantId);

                if (tenant == null)
                {
                    _logger.LogWarning("Tenant {TenantId} not found for manual contract processing", tenantId);
                    return;
                }

                var isExpired = await _leaseCalculationService.IsLeaseExpired(tenantId);

                if (isExpired && tenant.Property != null)
                {
                    // Mark property as available
                    tenant.Property.Status = "Available";
                    tenant.Property.UpdatedAt = DateTime.UtcNow;
                    await _unitOfWork.SaveChangesAsync();

                    // Send notifications
                    await _notificationService.CreateNotificationAsync(
                        tenant.UserId,
                        "Contract Manually Processed",
                        $"Your lease for {tenant.Property.Name} has been processed. The property is now available for new rentals.",
                        "contract_expired",
                        tenant.PropertyId);

                    if (tenant.Property.OwnerId != null)
                    {
                        await _notificationService.CreateNotificationAsync(
                            tenant.Property.OwnerId,
                            "Contract Manually Processed",
                            $"The tenant contract for {tenant.Property.Name} has been processed. The property is now available for new bookings.",
                            "contract_expired",
                            tenant.PropertyId);
                    }

                    _logger.LogInformation("Manually processed contract expiration for tenant {TenantId}", tenantId);
                }
                else
                {
                    _logger.LogWarning("Tenant {TenantId} contract is not expired, cannot process", tenantId);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error manually processing contract for tenant {TenantId}", tenantId);
                throw;
            }
        }

        public async Task SendExpirationReminderAsync(int tenantId, int daysUntilExpiration)
        {
            try
            {
                var tenant = await _context.Tenants
                    .Include(t => t.User)
                    .Include(t => t.Property)
                    .ThenInclude(p => p.Owner)
                    .FirstOrDefaultAsync(t => t.TenantId == tenantId);

                if (tenant == null)
                {
                    _logger.LogWarning("Tenant {TenantId} not found for expiration reminder", tenantId);
                    return;
                }

                // Send reminder to tenant
                await _notificationService.CreateNotificationAsync(
                    tenant.UserId,
                    "Contract Expiration Reminder",
                    $"Reminder: Your lease for {tenant.Property?.Name ?? "your property"} expires in {daysUntilExpiration} days. Please contact your landlord about renewal.",
                    "contract_reminder",
                    tenant.PropertyId);

                // Send reminder to landlord
                if (tenant.Property?.OwnerId != null)
                {
                    await _notificationService.CreateNotificationAsync(
                        tenant.Property.OwnerId,
                        "Tenant Contract Reminder",
                        $"Reminder: Tenant contract for {tenant.Property.Name} expires in {daysUntilExpiration} days.",
                        "contract_reminder",
                        tenant.PropertyId);
                }

                _logger.LogInformation("Sent expiration reminder for tenant {TenantId} ({DaysUntilExpiration} days)", 
                    tenantId, daysUntilExpiration);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error sending expiration reminder for tenant {TenantId}", tenantId);
                throw;
            }
        }

        #endregion
    }
} 