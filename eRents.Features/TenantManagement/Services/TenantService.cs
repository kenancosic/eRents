using AutoMapper;
using eRents.Domain.Models;
using eRents.Features.Core;
using eRents.Features.TenantManagement.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using eRents.Domain.Shared.Interfaces;
using System.Threading.Tasks;
using System.Linq;

namespace eRents.Features.TenantManagement.Services
{
    public class TenantService : BaseCrudService<Tenant, TenantRequest, TenantResponse, TenantSearch>
    {
        public TenantService(
            DbContext context,
            IMapper mapper,
            ILogger<TenantService> logger,
            ICurrentUserService? currentUserService = null)
            : base(context, mapper, logger, currentUserService)
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

            // Username contains (case-insensitive)
            if (!string.IsNullOrWhiteSpace(search.UsernameContains))
            {
                var pattern = $"%{search.UsernameContains.Trim()}%";
                query = query.Where(x => x.User != null && EF.Functions.Like(x.User.Username!, pattern));
            }

            // Name contains: first or last name (case-insensitive)
            if (!string.IsNullOrWhiteSpace(search.NameContains))
            {
                var pattern = $"%{search.NameContains.Trim()}%";
                query = query.Where(x => x.User != null &&
                    (EF.Functions.Like(x.User.FirstName ?? string.Empty, pattern) ||
                     EF.Functions.Like(x.User.LastName ?? string.Empty, pattern)));
            }

            // City contains: property's address city
            if (!string.IsNullOrWhiteSpace(search.CityContains))
            {
                var pattern = $"%{search.CityContains.Trim()}%";
                query = query.Where(x => x.Property != null && x.Property.Address != null &&
                                         EF.Functions.Like(x.Property.Address.City ?? string.Empty, pattern));
            }

            // Auto-scope for Desktop owners/landlords: only tenants tied to properties owned by current user
            if (CurrentUser?.IsDesktop == true &&
                !string.IsNullOrWhiteSpace(CurrentUser.UserRole) &&
                (string.Equals(CurrentUser.UserRole, "Owner", StringComparison.OrdinalIgnoreCase) ||
                 string.Equals(CurrentUser.UserRole, "Landlord", StringComparison.OrdinalIgnoreCase)))
            {
                var ownerId = CurrentUser.GetUserIdAsInt();
                if (ownerId.HasValue)
                {
                    query = query.Where(x => x.Property != null && x.Property.OwnerId == ownerId.Value);
                }
            }

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

        public override async Task<TenantResponse> GetByIdAsync(int id)
        {
            var entity = await AddIncludes(Context.Set<Tenant>().AsQueryable())
                .FirstOrDefaultAsync(x => x.TenantId == id);

            if (entity == null)
                throw new KeyNotFoundException($"Tenant with id {id} not found");

            if (CurrentUser?.IsDesktop == true &&
                !string.IsNullOrWhiteSpace(CurrentUser.UserRole) &&
                (string.Equals(CurrentUser.UserRole, "Owner", StringComparison.OrdinalIgnoreCase) ||
                 string.Equals(CurrentUser.UserRole, "Landlord", StringComparison.OrdinalIgnoreCase)))
            {
                var ownerId = CurrentUser.GetUserIdAsInt();
                if (!ownerId.HasValue || entity.Property == null || entity.Property.OwnerId != ownerId.Value)
                    throw new KeyNotFoundException($"Tenant with id {id} not found");
            }

            return Mapper.Map<TenantResponse>(entity);
        }

        protected override async Task BeforeCreateAsync(Tenant entity, TenantRequest request)
        {
            if (CurrentUser?.IsDesktop == true &&
                !string.IsNullOrWhiteSpace(CurrentUser.UserRole) &&
                (string.Equals(CurrentUser.UserRole, "Owner", StringComparison.OrdinalIgnoreCase) ||
                 string.Equals(CurrentUser.UserRole, "Landlord", StringComparison.OrdinalIgnoreCase)))
            {
                var ownerId = CurrentUser.GetUserIdAsInt();
                if (!ownerId.HasValue)
                    throw new KeyNotFoundException("Property not found");

                var property = await Context.Set<Property>().AsNoTracking()
                    .FirstOrDefaultAsync(p => p.PropertyId == entity.PropertyId);
                if (property == null || property.OwnerId != ownerId.Value)
                    throw new KeyNotFoundException("Property not found");
            }
        }

        protected override async Task BeforeUpdateAsync(Tenant entity, TenantRequest request)
        {
            if (CurrentUser?.IsDesktop == true &&
                !string.IsNullOrWhiteSpace(CurrentUser.UserRole) &&
                (string.Equals(CurrentUser.UserRole, "Owner", StringComparison.OrdinalIgnoreCase) ||
                 string.Equals(CurrentUser.UserRole, "Landlord", StringComparison.OrdinalIgnoreCase)))
            {
                var ownerId = CurrentUser.GetUserIdAsInt();
                if (!ownerId.HasValue)
                    throw new KeyNotFoundException($"Tenant with id {entity.TenantId} not found");

                var property = await Context.Set<Property>().AsNoTracking()
                    .FirstOrDefaultAsync(p => p.PropertyId == entity.PropertyId);
                if (property == null || property.OwnerId != ownerId.Value)
                    throw new KeyNotFoundException($"Tenant with id {entity.TenantId} not found");
            }
        }

        protected override async Task BeforeDeleteAsync(Tenant entity)
        {
            if (CurrentUser?.IsDesktop == true &&
                !string.IsNullOrWhiteSpace(CurrentUser.UserRole) &&
                (string.Equals(CurrentUser.UserRole, "Owner", StringComparison.OrdinalIgnoreCase) ||
                 string.Equals(CurrentUser.UserRole, "Landlord", StringComparison.OrdinalIgnoreCase)))
            {
                var ownerId = CurrentUser.GetUserIdAsInt();
                if (!ownerId.HasValue)
                    throw new KeyNotFoundException($"Tenant with id {entity.TenantId} not found");

                var property = await Context.Set<Property>().AsNoTracking()
                    .FirstOrDefaultAsync(p => p.PropertyId == entity.PropertyId);
                if (property == null || property.OwnerId != ownerId.Value)
                    throw new KeyNotFoundException($"Tenant with id {entity.TenantId} not found");
            }
        }
    }
}