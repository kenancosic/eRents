using eRents.Domain.Models;
using eRents.Domain.Shared;

namespace eRents.Domain.Repositories
{
    public interface ITenantRepository : IBaseRepository<Tenant>
    {
        // Current Tenants for Landlord (users with active bookings in landlord's properties)
        Task<List<User>> GetCurrentTenantsForLandlordAsync(int landlordId, Dictionary<string, string>? filters = null);
        
        // Tenant-Property Relationship Management
        Task<List<Tenant>> GetTenantRelationshipsForLandlordAsync(int landlordId);
        Task<Tenant?> GetTenantByUserAndPropertyAsync(int userId, int propertyId);
        Task<Dictionary<int, Property?>> GetTenantPropertyAssignmentsAsync(List<int> userIds, int landlordId);
        
        // Tenant Performance Metrics
        Task<List<User>> GetTenantsWithMetricsForLandlordAsync(int landlordId);
        Task<int> GetTotalBookingsForTenantAsync(int userId, int landlordId);
        Task<decimal> GetTotalRevenueFromTenantAsync(int userId, int landlordId);
        Task<int> GetMaintenanceIssuesReportedByTenantAsync(int userId, int landlordId);
        
        // Active/Current Tenants (those with ongoing bookings)
        Task<List<User>> GetActiveTenantsForLandlordAsync(int landlordId);
        Task<bool> IsTenantCurrentlyActiveAsync(int userId, int landlordId);
    }
} 