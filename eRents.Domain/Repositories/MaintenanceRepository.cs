using eRents.Domain.Models;
using eRents.Domain.Shared;
using eRents.Shared.SearchObjects;
using Microsoft.EntityFrameworkCore;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace eRents.Domain.Repositories
{
    public class MaintenanceRepository : BaseRepository<MaintenanceIssue>, IMaintenanceRepository
    {
        public MaintenanceRepository(ERentsContext context) : base(context) { }

        public async Task<int> GetOpenIssuesCountAsync()
        {
            return await _context.MaintenanceIssues.AsNoTracking().CountAsync(m => m.Status.StatusName == "Open");
        }

        public async Task<int> GetPendingIssuesCountAsync()
        {
            return await _context.MaintenanceIssues.AsNoTracking().CountAsync(m => m.Status.StatusName == "Pending");
        }

        public async Task<int> GetHighPriorityIssuesCountAsync()
        {
            return await _context.MaintenanceIssues.AsNoTracking().CountAsync(m => m.Priority.PriorityName == "High" || m.Priority.PriorityName == "Emergency" || m.Priority.PriorityName == "Urgent");
        }

        public async Task<int> GetTenantComplaintsCountAsync()
        {
            return await _context.MaintenanceIssues.AsNoTracking().CountAsync(m => m.IsTenantComplaint);
        }

        public async Task<IEnumerable<MaintenanceIssue>> GetAllAsync(MaintenanceIssueSearchObject searchObject)
        {
            var query = _context.MaintenanceIssues
                .Include(m => m.Images)
                .AsNoTracking()
                .AsQueryable();

            if (searchObject != null)
            {
                if (searchObject.PropertyId.HasValue)
                    query = query.Where(m => m.PropertyId == searchObject.PropertyId);
                if (!string.IsNullOrEmpty(searchObject.Status))
                    query = query.Where(m => m.Status.StatusName == searchObject.Status);
                if (!string.IsNullOrEmpty(searchObject.Priority))
                    query = query.Where(m => m.Priority.PriorityName == searchObject.Priority);
                if (searchObject.AssignedTo.HasValue)
                    query = query.Where(m => m.AssignedTo == searchObject.AssignedTo);
                if (searchObject.ReportedBy.HasValue)
                    query = query.Where(m => m.TenantId == searchObject.ReportedBy);
                if (!string.IsNullOrEmpty(searchObject.Category))
                    query = query.Where(m => m.Category == searchObject.Category);
                if (searchObject.IsTenantComplaint.HasValue)
                    query = query.Where(m => m.IsTenantComplaint == searchObject.IsTenantComplaint);
                if (searchObject.RequiresInspection.HasValue)
                    query = query.Where(m => m.RequiresInspection == searchObject.RequiresInspection);
                if (searchObject.CreatedFrom.HasValue)
                    query = query.Where(m => m.DateReported >= searchObject.CreatedFrom);
                if (searchObject.CreatedTo.HasValue)
                    query = query.Where(m => m.DateReported <= searchObject.CreatedTo);
            }

            return await query.ToListAsync();
        }
    }
} 