using eRents.Domain.Models;
using eRents.Domain.Shared;
using eRents.Shared.SearchObjects;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace eRents.Domain.Repositories
{
    public interface IMaintenanceRepository : IBaseRepository<MaintenanceIssue>
    {
        Task<int> GetOpenIssuesCountAsync(IEnumerable<int> propertyIds);
        Task<int> GetPendingIssuesCountAsync(IEnumerable<int> propertyIds);
        Task<int> GetHighPriorityIssuesCountAsync(IEnumerable<int> propertyIds);
        Task<int> GetTenantComplaintsCountAsync(IEnumerable<int> propertyIds);
        Task<IEnumerable<MaintenanceIssue>> GetAllAsync(MaintenanceIssueSearchObject searchObject);
        // Add more as needed for statistics
    }
} 