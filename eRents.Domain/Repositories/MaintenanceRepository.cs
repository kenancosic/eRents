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

		public override async Task<MaintenanceIssue> GetByIdAsync(int id)
		{
			return await _context.MaintenanceIssues
				.Include(m => m.Images)
				.Include(m => m.Priority)
				.Include(m => m.Status)
				.AsNoTracking()
				.FirstOrDefaultAsync(m => m.MaintenanceIssueId == id);
		}

		public async Task<int> GetOpenIssuesCountAsync(IEnumerable<int> propertyIds)
		{
			return await _context.MaintenanceIssues.AsNoTracking()
				.Where(m => propertyIds.Contains(m.PropertyId) && m.Status.StatusName == "pending")
				.CountAsync();
		}

		public async Task<int> GetPendingIssuesCountAsync(IEnumerable<int> propertyIds)
		{
			return await _context.MaintenanceIssues.AsNoTracking()
				.Where(m => propertyIds.Contains(m.PropertyId) && m.Status.StatusName == "pending")
				.CountAsync();
		}

		public async Task<int> GetHighPriorityIssuesCountAsync(IEnumerable<int> propertyIds)
		{
			return await _context.MaintenanceIssues.AsNoTracking()
				.Where(m => propertyIds.Contains(m.PropertyId) && (m.Priority.PriorityName == "High" || m.Priority.PriorityName == "Emergency"))
				.CountAsync();
		}

		public async Task<int> GetTenantComplaintsCountAsync(IEnumerable<int> propertyIds)
		{
			return await _context.MaintenanceIssues.AsNoTracking()
				.Where(m => propertyIds.Contains(m.PropertyId) && m.IsTenantComplaint)
				.CountAsync();
		}

		public async Task<IEnumerable<MaintenanceIssue>> GetAllAsync(MaintenanceIssueSearchObject searchObject)
		{
			var query = _context.MaintenanceIssues
					.Include(m => m.Images)
					.Include(m => m.Priority)
					.Include(m => m.Status)
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
					query = query.Where(m => m.AssignedToUserId == searchObject.AssignedTo);
				if (searchObject.ReportedBy.HasValue)
					query = query.Where(m => m.ReportedByUserId == searchObject.ReportedBy);
				if (!string.IsNullOrEmpty(searchObject.Category))
					query = query.Where(m => m.Category == searchObject.Category);
				if (searchObject.IsTenantComplaint.HasValue)
					query = query.Where(m => m.IsTenantComplaint == searchObject.IsTenantComplaint);
				if (searchObject.RequiresInspection.HasValue)
					query = query.Where(m => m.RequiresInspection == searchObject.RequiresInspection);
				if (searchObject.CreatedAt.HasValue)
					query = query.Where(m => m.CreatedAt >= searchObject.CreatedAt);
			}

			return await query.ToListAsync();
		}
	}
}