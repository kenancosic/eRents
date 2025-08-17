using AutoMapper;
using eRents.Domain.Models;
using eRents.Features.Core;
using eRents.Features.PropertyManagement.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using eRents.Domain.Shared.Interfaces;
using System;
using System.Threading.Tasks;
using System.Linq;
using eRents.Domain.Models.Enums;

namespace eRents.Features.PropertyManagement.Services
{
    public class PropertyService : BaseCrudService<Property, PropertyRequest, PropertyResponse, PropertySearch>
    {
        public PropertyService(
            DbContext context,
            IMapper mapper,
            ILogger<PropertyService> logger,
            ICurrentUserService? currentUserService = null)
            : base(context, mapper, logger, currentUserService)
        {
        }

        protected override IQueryable<Property> AddIncludes(IQueryable<Property> query)
        {
            return query
                .Include(p => p.Owner)
                .Include(p => p.Address)
                .Include(p => p.Images)
                .Include(p => p.Amenities);
        }

        protected override IQueryable<Property> AddFilter(IQueryable<Property> query, PropertySearch search)
        {
            if (!string.IsNullOrWhiteSpace(search.NameContains))
                query = query.Where(x => x.Name.Contains(search.NameContains));

            if (search.MinPrice.HasValue)
                query = query.Where(x => x.Price >= search.MinPrice.Value);

            if (search.MaxPrice.HasValue)
                query = query.Where(x => x.Price <= search.MaxPrice.Value);

            if (!string.IsNullOrWhiteSpace(search.City))
                query = query.Where(x => x.Address != null && x.Address.City == search.City);

            if (search.PropertyType.HasValue)
                query = query.Where(x => x.PropertyType == search.PropertyType.Value);

            if (search.RentingType.HasValue)
                query = query.Where(x => x.RentingType == search.RentingType.Value);

            if (search.Status.HasValue)
                query = query.Where(x => x.Status == search.Status.Value);

            // Auto-scope for Desktop owners/landlords
            // Note: Seeded  user "desktop" has role "Owner" (UserTypeEnum.Owner)
            // Support both "Owner" and "Landlord" to be robust across datasets
            if (CurrentUser?.IsDesktop == true &&
                !string.IsNullOrWhiteSpace(CurrentUser.UserRole) &&
                (string.Equals(CurrentUser.UserRole, "Owner", StringComparison.OrdinalIgnoreCase) ||
                 string.Equals(CurrentUser.UserRole, "Landlord", StringComparison.OrdinalIgnoreCase)))
            {
                var ownerId = CurrentUser.GetUserIdAsInt();
                if (ownerId.HasValue)
                {
                    query = query.Where(x => x.OwnerId == ownerId.Value);
                }
            }

            return query;
        }

        protected override IQueryable<Property> AddSorting(IQueryable<Property> query, PropertySearch search)
        {
            var sortBy = (search.SortBy ?? string.Empty).Trim().ToLowerInvariant();
            var sortDir = (search.SortDirection ?? "asc").Trim().ToLowerInvariant();
            var desc = sortDir == "desc";

            return sortBy switch
            {
                "price"     => desc ? query.OrderByDescending(x => x.Price)     : query.OrderBy(x => x.Price),
                "name"      => desc ? query.OrderByDescending(x => x.Name)      : query.OrderBy(x => x.Name),
                "createdat" => desc ? query.OrderByDescending(x => x.CreatedAt) : query.OrderBy(x => x.CreatedAt),
                "updatedat" => desc ? query.OrderByDescending(x => x.UpdatedAt) : query.OrderBy(x => x.UpdatedAt),
                _           => desc ? query.OrderByDescending(x => x.PropertyId) : query.OrderBy(x => x.PropertyId)
            };
        }

        public override async Task<PropertyResponse> GetByIdAsync(int id)
        {
            // Fetch with includes
            var query = AddIncludes(Context.Set<Property>().AsQueryable());
            var entity = await query.FirstOrDefaultAsync(x => x.PropertyId == id);
            if (entity == null)
                throw new KeyNotFoundException($"Property with id {id} not found");

            // Desktop owner/landlord can only access their own property
            if (CurrentUser?.IsDesktop == true &&
                !string.IsNullOrWhiteSpace(CurrentUser.UserRole) &&
                (string.Equals(CurrentUser.UserRole, "Owner", StringComparison.OrdinalIgnoreCase) ||
                 string.Equals(CurrentUser.UserRole, "Landlord", StringComparison.OrdinalIgnoreCase)))
            {
                var ownerId = CurrentUser.GetUserIdAsInt();
                if (!ownerId.HasValue || entity.OwnerId != ownerId.Value)
                {
                    // Hide existence
                    throw new KeyNotFoundException($"Property with id {id} not found");
                }
            }

            return Mapper.Map<PropertyResponse>(entity);
        }

        public async Task<PropertyTenantSummary?> GetCurrentTenantSummaryAsync(int propertyId)
        {
            // Ensure property exists and enforce ownership rules
            var propQuery = AddIncludes(Context.Set<Property>().AsQueryable());
            var prop = await propQuery.FirstOrDefaultAsync(p => p.PropertyId == propertyId);
            if (prop == null)
                throw new KeyNotFoundException($"Property with id {propertyId} not found");

            if (CurrentUser?.IsDesktop == true &&
                !string.IsNullOrWhiteSpace(CurrentUser.UserRole) &&
                (string.Equals(CurrentUser.UserRole, "Owner", StringComparison.OrdinalIgnoreCase) ||
                 string.Equals(CurrentUser.UserRole, "Landlord", StringComparison.OrdinalIgnoreCase)))
            {
                var ownerId = CurrentUser.GetUserIdAsInt();
                if (!ownerId.HasValue || prop.OwnerId != ownerId.Value)
                    throw new KeyNotFoundException($"Property with id {propertyId} not found");
            }

            // Find the most relevant active tenant for this property
            var now = DateOnly.FromDateTime(DateTime.UtcNow);
            var tenant = await Context.Set<Tenant>()
                .Include(t => t.User)
                .Where(t => t.PropertyId == propertyId
                            && t.TenantStatus == TenantStatusEnum.Active
                            && (!t.LeaseEndDate.HasValue || t.LeaseEndDate.Value >= now))
                .OrderByDescending(t => t.LeaseStartDate)
                .FirstOrDefaultAsync();

            if (tenant == null)
                return null;

            var fullName = $"{tenant.User?.FirstName} {tenant.User?.LastName}".Trim();
            if (string.IsNullOrWhiteSpace(fullName))
                fullName = tenant.User?.Username ?? tenant.User?.Email;

            return new PropertyTenantSummary
            {
                TenantId = tenant.TenantId,
                UserId = tenant.UserId,
                FullName = fullName,
                Email = tenant.User?.Email,
                LeaseStartDate = tenant.LeaseStartDate,
                LeaseEndDate = tenant.LeaseEndDate,
                TenantStatus = tenant.TenantStatus,
            };
        }

        protected override Task BeforeCreateAsync(Property entity, PropertyRequest request)
        {
            // Ensure desktop owner/landlord creates only their own properties
            if (CurrentUser?.IsDesktop == true &&
                !string.IsNullOrWhiteSpace(CurrentUser.UserRole) &&
                (string.Equals(CurrentUser.UserRole, "Owner", StringComparison.OrdinalIgnoreCase) ||
                 string.Equals(CurrentUser.UserRole, "Landlord", StringComparison.OrdinalIgnoreCase)))
            {
                var ownerId = CurrentUser.GetUserIdAsInt();
                if (ownerId.HasValue)
                {
                    entity.OwnerId = ownerId.Value;
                }
            }
            return Task.CompletedTask;
        }

        protected override Task BeforeUpdateAsync(Property entity, PropertyRequest request)
        {
            // Enforce ownership on updates for desktop owner/landlord
            if (CurrentUser?.IsDesktop == true &&
                !string.IsNullOrWhiteSpace(CurrentUser.UserRole) &&
                (string.Equals(CurrentUser.UserRole, "Owner", StringComparison.OrdinalIgnoreCase) ||
                 string.Equals(CurrentUser.UserRole, "Landlord", StringComparison.OrdinalIgnoreCase)))
            {
                var ownerId = CurrentUser.GetUserIdAsInt();
                if (!ownerId.HasValue || entity.OwnerId != ownerId.Value)
                {
                    throw new KeyNotFoundException($"Property with id {entity.PropertyId} not found");
                }
            }
            return Task.CompletedTask;
        }

        protected override Task BeforeDeleteAsync(Property entity)
        {
            // Enforce ownership on deletes for desktop owner/landlord
            if (CurrentUser?.IsDesktop == true &&
                !string.IsNullOrWhiteSpace(CurrentUser.UserRole) &&
                (string.Equals(CurrentUser.UserRole, "Owner", StringComparison.OrdinalIgnoreCase) ||
                 string.Equals(CurrentUser.UserRole, "Landlord", StringComparison.OrdinalIgnoreCase)))
            {
                var ownerId = CurrentUser.GetUserIdAsInt();
                if (!ownerId.HasValue || entity.OwnerId != ownerId.Value)
                {
                    throw new KeyNotFoundException($"Property with id {entity.PropertyId} not found");
                }
            }
            return Task.CompletedTask;
        }
    }
}