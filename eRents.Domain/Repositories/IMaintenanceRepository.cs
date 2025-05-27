using eRents.Domain.Models;
using eRents.Domain.Shared;
using eRents.Shared.SearchObjects;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace eRents.Domain.Repositories
{
    public interface IMaintenanceRepository : IBaseRepository<MaintenanceIssue>
    {
        Task<int> GetOpenIssuesCountAsync();
        Task<int> GetPendingIssuesCountAsync();
        Task<int> GetHighPriorityIssuesCountAsync();
        Task<int> GetTenantComplaintsCountAsync();
        Task<IEnumerable<MaintenanceIssue>> GetAllAsync(MaintenanceIssueSearchObject searchObject);
        // Add more as needed for statistics
    }
} 