using System;
using System.Linq;
using eRents.Domain.Models;
using eRents.Domain.Models.Enums;
using eRents.Features.Core.Services;
using eRents.Features.MaintenanceManagement.Models;
using AutoMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace eRents.Features.MaintenanceManagement.Services
{
    public class MaintenanceIssueService : BaseCrudService<MaintenanceIssue, MaintenanceIssueRequest, MaintenanceIssueResponse, MaintenanceIssueSearch>
    {
        public MaintenanceIssueService(
            ERentsContext context,
            IMapper mapper,
            ILogger<MaintenanceIssueService> logger)
            : base(context, mapper, logger)
        {
        }

        protected override IQueryable<MaintenanceIssue> AddIncludes(IQueryable<MaintenanceIssue> query)
        {
            return query
                .Include(x => x.Property)
                .Include(x => x.AssignedToUser)
                .Include(x => x.ReportedByUser);
        }

        protected override IQueryable<MaintenanceIssue> AddFilter(IQueryable<MaintenanceIssue> query, MaintenanceIssueSearch search)
        {
            if (search.PropertyId.HasValue)
            {
                query = query.Where(x => x.PropertyId == search.PropertyId.Value);
            }

            if (search.Statuses != null && search.Statuses.Length > 0)
            {
                query = query.Where(x => search.Statuses.Contains(x.Status));
            }

            if (search.PriorityMin.HasValue)
            {
                query = query.Where(x => x.Priority >= search.PriorityMin.Value);
            }

            if (search.PriorityMax.HasValue)
            {
                query = query.Where(x => x.Priority <= search.PriorityMax.Value);
            }

            if (search.CreatedFrom.HasValue)
            {
                var from = search.CreatedFrom.Value;
                query = query.Where(x => x.CreatedAt >= from);
            }

            if (search.CreatedTo.HasValue)
            {
                var to = search.CreatedTo.Value;
                query = query.Where(x => x.CreatedAt <= to);
            }

            return query;
        }

        protected override IQueryable<MaintenanceIssue> AddSorting(IQueryable<MaintenanceIssue> query, MaintenanceIssueSearch search)
        {
            var sortBy = (search.SortBy ?? string.Empty).Trim().ToLower();
            var sortDir = (search.SortDirection ?? "asc").Trim().ToLower();
            var desc = sortDir == "desc";

            // Custom support for virtual/computed fields in DTO
            if (sortBy == "priorityseverity")
            {
                // Map enum to severity weight
                return desc
                    ? query.OrderByDescending(x => x.Priority == MaintenanceIssuePriorityEnum.Emergency ? 4
                                                          : x.Priority == MaintenanceIssuePriorityEnum.High ? 3
                                                          : x.Priority == MaintenanceIssuePriorityEnum.Medium ? 2 : 1)
                    : query.OrderBy(x => x.Priority == MaintenanceIssuePriorityEnum.Emergency ? 4
                                           : x.Priority == MaintenanceIssuePriorityEnum.High ? 3
                                           : x.Priority == MaintenanceIssuePriorityEnum.Medium ? 2 : 1);
            }

            return sortBy switch
            {
                "title" => desc ? query.OrderByDescending(x => x.Title) : query.OrderBy(x => x.Title),
                "status" => desc ? query.OrderByDescending(x => x.Status) : query.OrderBy(x => x.Status),
                "createdat" => desc ? query.OrderByDescending(x => x.CreatedAt) : query.OrderBy(x => x.CreatedAt),
                _ => desc ? query.OrderByDescending(x => x.MaintenanceIssueId) : query.OrderBy(x => x.MaintenanceIssueId)
            };
        }
    }
}
