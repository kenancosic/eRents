using eRents.Domain.Models;
using eRents.Domain.Shared;
using eRents.Shared.SearchObjects;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace eRents.Domain.Repositories
{
	public class MaintenanceRepository : ConcurrentBaseRepository<MaintenanceIssue>, IMaintenanceRepository
	{
		public MaintenanceRepository(ERentsContext context, ILogger<MaintenanceRepository> logger) : base(context, logger) { }

		public override async Task<MaintenanceIssue> GetByIdAsync(int id)
		{
			return await _context.MaintenanceIssues
				.Include(m => m.Images)
				.Include(m => m.Priority)
				.Include(m => m.Status)
				.FirstOrDefaultAsync(m => m.MaintenanceIssueId == id);
		}

		public async Task<int?> GetStatusIdByNameAsync(string statusName)
		{
			var status = await _context.IssueStatuses
				.AsNoTracking()
				.FirstOrDefaultAsync(s => s.StatusName == statusName);
			return status?.StatusId;
		}

		public async Task<int> CountByStatusAsync(IEnumerable<int> propertyIds, string statusName)
		{
			return await _context.MaintenanceIssues.AsNoTracking()
				.Where(m => propertyIds.Contains(m.PropertyId) && m.Status.StatusName == statusName)
				.CountAsync();
		}

		public async Task<int> CountByPriorityAsync(IEnumerable<int> propertyIds, params string[] priorityNames)
		{
			return await _context.MaintenanceIssues.AsNoTracking()
				.Where(m => propertyIds.Contains(m.PropertyId) && priorityNames.Contains(m.Priority.PriorityName))
				.CountAsync();
		}

		public async Task<int> CountTenantComplaintsAsync(IEnumerable<int> propertyIds)
		{
			return await _context.MaintenanceIssues.AsNoTracking()
				.Where(m => propertyIds.Contains(m.PropertyId) && m.IsTenantComplaint)
				.CountAsync();
		}

		// ✅ PURGED: Removed all deprecated statistics methods - using consolidated methods only

		public async Task<IEnumerable<MaintenanceIssue>> GetAllAsync(MaintenanceIssueSearchObject searchObject)
		{
			var query = GetQueryable()
					.Include(m => m.Images)
					.Include(m => m.Priority)
					.Include(m => m.Status)
					.AsNoTracking();

			query = ApplySearchFilters(query, searchObject);

			return await query.ToListAsync();
		}

		private IQueryable<MaintenanceIssue> ApplySearchFilters(IQueryable<MaintenanceIssue> query, MaintenanceIssueSearchObject searchObject)
		{
			if (searchObject == null) return query;

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

			return query;
		}
	}
}