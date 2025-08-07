using AutoMapper;
using eRents.Domain.Models;
using eRents.Features.Core.Services;
using eRents.Features.TenantManagement.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace eRents.Features.TenantManagement.Services
{
    public class TenantService : BaseCrudService<Tenant, TenantRequest, TenantResponse, TenantSearch>
    {
        public TenantService(
            DbContext context,
            IMapper mapper,
            ILogger<TenantService> logger)
            : base(context, mapper, logger)
        {
        }

        protected override IQueryable<Tenant> AddIncludes(IQueryable<Tenant> query)
        {
            // Eager-load relations commonly needed for DTOs/maps
            return query
                .Include(t => t.User)
                .Include(t => t.Property);
        }

        protected override IQueryable<Tenant> AddFilter(IQueryable<Tenant> query, TenantSearch search)
        {
            if (search.UserId.HasValue)
                query = query.Where(x => x.UserId == search.UserId.Value);

            if (search.PropertyId.HasValue)
                query = query.Where(x => x.PropertyId == search.PropertyId.Value);

            if (search.TenantStatus.HasValue)
                query = query.Where(x => x.TenantStatus == search.TenantStatus.Value);

            if (search.LeaseStartFrom.HasValue)
                query = query.Where(x => x.LeaseStartDate.HasValue && x.LeaseStartDate.Value >= search.LeaseStartFrom.Value);

            if (search.LeaseStartTo.HasValue)
                query = query.Where(x => x.LeaseStartDate.HasValue && x.LeaseStartDate.Value <= search.LeaseStartTo.Value);

            if (search.LeaseEndFrom.HasValue)
                query = query.Where(x => x.LeaseEndDate.HasValue && x.LeaseEndDate.Value >= search.LeaseEndFrom.Value);

            if (search.LeaseEndTo.HasValue)
                query = query.Where(x => x.LeaseEndDate.HasValue && x.LeaseEndDate.Value <= search.LeaseEndTo.Value);

            return query;
        }

        protected override IQueryable<Tenant> AddSorting(IQueryable<Tenant> query, TenantSearch search)
        {
            var sortBy = (search.SortBy ?? string.Empty).Trim().ToLowerInvariant();
            var sortDir = (search.SortDirection ?? "asc").Trim().ToLowerInvariant();
            var desc = sortDir == "desc";

            return sortBy switch
            {
                "leasestartdate" => desc ? query.OrderByDescending(x => x.LeaseStartDate) : query.OrderBy(x => x.LeaseStartDate),
                "leaseenddate"   => desc ? query.OrderByDescending(x => x.LeaseEndDate)   : query.OrderBy(x => x.LeaseEndDate),
                "createdat"      => desc ? query.OrderByDescending(x => x.CreatedAt)      : query.OrderBy(x => x.CreatedAt),
                "updatedat"      => desc ? query.OrderByDescending(x => x.UpdatedAt)      : query.OrderBy(x => x.UpdatedAt),
                _                => desc ? query.OrderByDescending(x => x.TenantId)        : query.OrderBy(x => x.TenantId)
            };
        }
    }
}