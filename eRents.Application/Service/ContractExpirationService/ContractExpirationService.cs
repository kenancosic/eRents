using eRents.Application.Service.NotificationService;
using eRents.Application.Service.RentalRequestService;
using eRents.Domain.Models;
using eRents.Domain.Repositories;
using eRents.Shared.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace eRents.Application.Service.ContractExpirationService
{
    /// <summary>
    /// Background service that monitors and processes contract expirations
    /// Runs daily to check for contracts expiring in 60 days and handle expired contracts
    /// </summary>
    public class ContractExpirationService : BackgroundService
    {
        private readonly IServiceProvider _serviceProvider;
        private readonly ILogger<ContractExpirationService> _logger;

        public ContractExpirationService(IServiceProvider serviceProvider, ILogger<ContractExpirationService> logger)
        {
            _serviceProvider = serviceProvider;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("ContractExpirationService started");

            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    using var scope = _serviceProvider.CreateScope();
                    
                    await CheckContractsExpiringIn60Days(scope.ServiceProvider);
                    await ProcessExpiredContracts(scope.ServiceProvider);
                    
                    _logger.LogInformation("Contract expiration check completed at {Time}", DateTime.UtcNow);
                    
                    // Run daily at midnight
                    await Task.Delay(TimeSpan.FromDays(1), stoppingToken);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error in ContractExpirationService");
                    
                    // Wait 1 hour before retrying on error
                    await Task.Delay(TimeSpan.FromHours(1), stoppingToken);
                }
            }
        }

        private async Task CheckContractsExpiringIn60Days(IServiceProvider serviceProvider)
        {
            var tenantRepository = serviceProvider.GetRequiredService<ITenantRepository>();
            var rentalRequestRepository = serviceProvider.GetRequiredService<IRentalRequestRepository>();
            var notificationService = serviceProvider.GetRequiredService<INotificationService>();

            var targetDate = DateOnly.FromDateTime(DateTime.UtcNow.AddDays(60));
            
            _logger.LogInformation("Checking for contracts expiring on {TargetDate}", targetDate);

            // Get tenants with leases expiring in 60 days
            var expiringContracts = await tenantRepository.GetQueryable()
                .Include(t => t.User)
                .Include(t => t.Property)
                    .ThenInclude(p => p.Owner)
                .Where(t => t.TenantStatus == "Active" && t.LeaseStartDate.HasValue)
                .ToListAsync();
                
            // Filter by calculated lease end date
            var filtered = expiringContracts.Where(t => 
            {
                var originalRequest = rentalRequestRepository.GetQueryable()
                    .Where(r => r.UserId == t.UserId && r.PropertyId == t.PropertyId && r.Status == "Approved")
                    .OrderByDescending(r => r.RequestDate)
                    .FirstOrDefault();
                
                if (originalRequest == null) return false;
                
                var leaseEndDate = t.LeaseStartDate.Value.AddMonths(originalRequest.LeaseDurationMonths);
                return leaseEndDate.ToDateTime(TimeOnly.MinValue) <= targetDate.ToDateTime(TimeOnly.MinValue);
            }).ToList();
                
            foreach (var tenant in filtered)
            {
                try
                {
                    // Notify tenant
                    await notificationService.CreateNotificationAsync(tenant.UserId, 
                        "Contract Expiring Soon",
                        $"Your lease for {tenant.Property.Name} expires in 2 months. Please contact your landlord to discuss renewal.",
                        "contract_expiring");
                        
                    // Notify landlord  
                    await notificationService.CreateNotificationAsync(tenant.Property.OwnerId,
                        "Tenant Contract Expiring", 
                        $"Tenant contract for {tenant.Property.Name} expires in 2 months. Please discuss renewal with tenant.",
                        "contract_expiring");

                    _logger.LogInformation("Sent expiring contract notifications for property {PropertyId}", tenant.PropertyId);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Failed to send notifications for expiring contract - Property {PropertyId}", tenant.PropertyId);
                }
            }

            _logger.LogInformation("Processed {Count} expiring contracts", filtered.Count);
        }
        
        private async Task ProcessExpiredContracts(IServiceProvider serviceProvider)
        {
            var tenantRepository = serviceProvider.GetRequiredService<ITenantRepository>();
            var propertyRepository = serviceProvider.GetRequiredService<IPropertyRepository>();
            var rentalRequestRepository = serviceProvider.GetRequiredService<IRentalRequestRepository>();
            var notificationService = serviceProvider.GetRequiredService<INotificationService>();

            var today = DateOnly.FromDateTime(DateTime.UtcNow);
            
            _logger.LogInformation("Processing expired contracts as of {Today}", today);
            
            // Get all active tenants and check calculated lease end dates
            var activeTenants = await tenantRepository.GetQueryable()
                .Include(t => t.Property)
                .Where(t => t.TenantStatus == "Active" && t.LeaseStartDate.HasValue)
                .ToListAsync();
                
            var expiredContracts = activeTenants.Where(t =>
            {
                var originalRequest = rentalRequestRepository.GetQueryable()
                    .Where(r => r.UserId == t.UserId && r.PropertyId == t.PropertyId && r.Status == "Approved")
                    .OrderByDescending(r => r.RequestDate)
                    .FirstOrDefault();
                    
                if (originalRequest == null) return false;
                
                var leaseEndDate = t.LeaseStartDate.Value.AddMonths(originalRequest.LeaseDurationMonths);
                return leaseEndDate.ToDateTime(TimeOnly.MinValue) <= today.ToDateTime(TimeOnly.MinValue);
            }).ToList();
                
            foreach (var tenant in expiredContracts)
            {
                try
                {
                    // Mark property as available for rental
                    tenant.Property.Status = "Available";
                    await propertyRepository.UpdateAsync(tenant.Property);
                    
                    // Keep tenant contract active (no restrictions on extensions)
                    // Tenant can still request extensions even after property is listed
                    
                    // Notify both parties about contract expiration
                    await notificationService.CreateNotificationAsync(tenant.UserId,
                        "Contract Expired",
                        $"Your lease for {tenant.Property.Name} has expired. The property is now available for new rentals, but you can still request an extension.",
                        "contract_expired");
                        
                    await notificationService.CreateNotificationAsync(tenant.Property.OwnerId,
                        "Contract Expired",
                        $"The tenant contract for {tenant.Property.Name} has expired. The property is now available for new bookings.",
                        "contract_expired");

                    _logger.LogInformation("Processed expired contract for property {PropertyId} - Property marked as available", tenant.PropertyId);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Failed to process expired contract for property {PropertyId}", tenant.PropertyId);
                }
            }

            _logger.LogInformation("Processed {Count} expired contracts", expiredContracts.Count);
        }
    }
} 