using eRents.Domain.Models;
using eRents.Domain.Shared;
using eRents.Shared.SearchObjects;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace eRents.Domain.Repositories
{
    public interface IMaintenanceRepository : IBaseRepository<MaintenanceIssue>
    {
        // ✅ PROPER REPOSITORY METHODS: Entity-specific operations only
        Task<int?> GetStatusIdByNameAsync(string statusName);
        Task<IEnumerable<MaintenanceIssue>> GetAllAsync(MaintenanceIssueSearchObject searchObject);
        
        // ✅ CONSOLIDATED: Clean counting methods for StatisticsService
        Task<int> CountByStatusAsync(IEnumerable<int> propertyIds, string statusName);
        Task<int> CountByPriorityAsync(IEnumerable<int> propertyIds, params string[] priorityNames);
        Task<int> CountTenantComplaintsAsync(IEnumerable<int> propertyIds);
    }
} 