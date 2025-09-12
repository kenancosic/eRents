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

            // For mobile/client users (non-desktop), ensure the UserId comes from the authenticated context,
            // not from the incoming payload, and mark the request as Inactive (pending) by default.
            if (CurrentUser?.IsDesktop != true)
            {
                var userId = CurrentUser?.GetUserIdAsInt();
                if (!userId.HasValue)
                {
                    throw new InvalidOperationException("Authenticated user context is required to create a tenant request.");
                }
                entity.UserId = userId.Value;
                // A tenant request is pending by default until landlord accepts
                entity.TenantStatus = eRents.Domain.Models.Enums.TenantStatusEnum.Inactive;
            }

            // Validate that a property exists and is monthly rental when provided
            if (entity.PropertyId.HasValue)
            {
                var property = await Context.Set<Property>()
                    .AsNoTracking()
                    .FirstOrDefaultAsync(p => p.PropertyId == entity.PropertyId!.Value);
                if (property == null)
                {
                    throw new KeyNotFoundException("Property not found");
                }
                if (property.RentingType != eRents.Domain.Models.Enums.RentalType.Monthly)
                {
                    throw new InvalidOperationException("Tenant requests can only be created for monthly rentals.");
                }
                if (property.Status != eRents.Domain.Models.Enums.PropertyStatusEnum.Available)
                {
                    throw new InvalidOperationException("Property is not available for new tenants.");
                }
            }

            // Default LeaseStartDate to today if not provided
            if (!entity.LeaseStartDate.HasValue)
            {
                entity.LeaseStartDate = DateOnly.FromDateTime(DateTime.UtcNow.Date);
            }

            // Prevent creating a tenancy if there are non-cancelled bookings scheduled from LeaseStartDate onward
            if (entity.PropertyId.HasValue)
            {
                var leaseStart = entity.LeaseStartDate!.Value;
                var hasFutureBookings = await Context.Set<Booking>()
                    .AsNoTracking()
                    .Where(b => b.PropertyId == entity.PropertyId!.Value)
                    .Where(b => b.Status != eRents.Domain.Models.Enums.BookingStatusEnum.Cancelled)
                    .Where(b => (b.EndDate.HasValue ? b.EndDate.Value >= leaseStart : b.StartDate >= leaseStart))
                    .AnyAsync();

                if (hasFutureBookings)
                {
                    throw new InvalidOperationException("Cannot start monthly tenancy: property has scheduled bookings from the selected start date.");
                }
            }
        }

        /// <summary>
        /// Reject a pending (Inactive) tenant request.
        /// </summary>
        public async Task<TenantResponse> RejectTenantRequestAsync(int tenantId)
        {
            var entity = await AddIncludes(Context.Set<Tenant>().AsQueryable())
                .FirstOrDefaultAsync(t => t.TenantId == tenantId);

            if (entity == null)
                throw new KeyNotFoundException($"Tenant with id {tenantId} not found");

            // Validate ownership for desktop owner/landlord
            if (CurrentUser?.IsDesktop == true &&
                !string.IsNullOrWhiteSpace(CurrentUser.UserRole) &&
                (string.Equals(CurrentUser.UserRole, "Owner", StringComparison.OrdinalIgnoreCase) ||
                 string.Equals(CurrentUser.UserRole, "Landlord", StringComparison.OrdinalIgnoreCase)))
            {
                var ownerId = CurrentUser.GetUserIdAsInt();
                if (!ownerId.HasValue || entity.Property == null || entity.Property.OwnerId != ownerId.Value)
                    throw new KeyNotFoundException($"Tenant with id {tenantId} not found");
            }

            if (entity.TenantStatus != eRents.Domain.Models.Enums.TenantStatusEnum.Inactive)
            {
                throw new InvalidOperationException("Only pending tenant requests can be rejected.");
            }

            entity.TenantStatus = eRents.Domain.Models.Enums.TenantStatusEnum.Evicted;
            entity.UpdatedAt = DateTime.UtcNow;
            await Context.SaveChangesAsync();

            return Mapper.Map<TenantResponse>(entity);
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

            // If lease start is being set/changed and property is assigned, re-check future bookings conflict
            if (entity.PropertyId.HasValue && entity.LeaseStartDate.HasValue)
            {
                var leaseStart = entity.LeaseStartDate.Value;
                var hasFutureBookings = await Context.Set<Booking>()
                    .AsNoTracking()
                    .Where(b => b.PropertyId == entity.PropertyId!.Value)
                    .Where(b => b.Status != eRents.Domain.Models.Enums.BookingStatusEnum.Cancelled)
                    .Where(b => (b.EndDate.HasValue ? b.EndDate.Value >= leaseStart : b.StartDate >= leaseStart))
                    .AnyAsync();

                if (hasFutureBookings)
                {
                    throw new InvalidOperationException("Cannot update tenancy: property has scheduled bookings from the lease start date.");
                }
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

        public async Task<TenantResponse> CancelTenantAsync(int tenantId, DateOnly? cancelDate = null)
        {
            // Load with property for ownership validation
            var entity = await AddIncludes(Context.Set<Tenant>().AsQueryable())
                .FirstOrDefaultAsync(t => t.TenantId == tenantId);

            if (entity == null)
                throw new KeyNotFoundException($"Tenant with id {tenantId} not found");

            if (CurrentUser?.IsDesktop == true &&
                !string.IsNullOrWhiteSpace(CurrentUser.UserRole) &&
                (string.Equals(CurrentUser.UserRole, "Owner", StringComparison.OrdinalIgnoreCase) ||
                 string.Equals(CurrentUser.UserRole, "Landlord", StringComparison.OrdinalIgnoreCase)))
            {
                var ownerId = CurrentUser.GetUserIdAsInt();
                if (!ownerId.HasValue || entity.Property == null || entity.Property.OwnerId != ownerId.Value)
                    throw new KeyNotFoundException($"Tenant with id {tenantId} not found");
            }

            // Determine effective cancellation date and compute end of next billing cycle
            var leaseStart = entity.LeaseStartDate ?? DateOnly.FromDateTime(DateTime.UtcNow.Date);
            var cancelOn = cancelDate ?? DateOnly.FromDateTime(DateTime.UtcNow.Date);

            var effectiveEnd = ComputeLeaseEndForCancellation(leaseStart, cancelOn);
            entity.LeaseEndDate = effectiveEnd;
            entity.TenantStatus = eRents.Domain.Models.Enums.TenantStatusEnum.LeaseEnded;

            await Context.SaveChangesAsync();
            return Mapper.Map<TenantResponse>(entity);
        }

        private static DateOnly ComputeLeaseEndForCancellation(DateOnly leaseStart, DateOnly cancelOn)
        {
            // Billing cycles start each month on the leaseStart's day (adjusted for shorter months)
            // End date is inclusive: end of the cycle day before the next cycle start
            // Rule: owe the entire next cycle beyond the current one when cancelling

            // Calculate months difference between cancelOn and leaseStart
            var monthsBetween = (cancelOn.Year - leaseStart.Year) * 12 + (cancelOn.Month - leaseStart.Month);
            if (monthsBetween < 0) monthsBetween = 0;

            var currentCycleStart = leaseStart.AddMonths(monthsBetween);

            DateOnly nextCycleStart;
            if (cancelOn < currentCycleStart)
            {
                // Cancellation before the current cycle started -> next cycle is currentCycleStart
                nextCycleStart = currentCycleStart;
            }
            else
            {
                // Cancellation within or after the current cycle -> next cycle starts one month after currentCycleStart
                nextCycleStart = currentCycleStart.AddMonths(1);
            }

            // Owe one full cycle beyond the nextCycleStart
            var owedCycleEnd = nextCycleStart.AddMonths(1).AddDays(-1);
            return owedCycleEnd;
        }

        /// <summary>
        /// Accepts a tenant request and automatically rejects all other inactive requests for the same property
        /// </summary>
        /// <param name="tenantId">ID of the tenant to accept</param>
        /// <returns>Updated tenant response</returns>
        public async Task<TenantResponse> AcceptTenantAndRejectOthersAsync(int tenantId)
        {
            using var transaction = await Context.Database.BeginTransactionAsync();
            try
            {
                // Get the tenant to accept
                var tenantToAccept = await Context.Set<Tenant>()
                    .Include(t => t.Property)
                    .FirstOrDefaultAsync(t => t.TenantId == tenantId);

                if (tenantToAccept == null)
                    throw new KeyNotFoundException($"Tenant with id {tenantId} not found");

                // Validate ownership for desktop owner/landlord
                if (CurrentUser?.IsDesktop == true &&
                    !string.IsNullOrWhiteSpace(CurrentUser.UserRole) &&
                    (string.Equals(CurrentUser.UserRole, "Owner", StringComparison.OrdinalIgnoreCase) ||
                     string.Equals(CurrentUser.UserRole, "Landlord", StringComparison.OrdinalIgnoreCase)))
                {
                    var ownerId = CurrentUser.GetUserIdAsInt();
                    if (!ownerId.HasValue || tenantToAccept.Property == null || tenantToAccept.Property.OwnerId != ownerId.Value)
                        throw new KeyNotFoundException($"Tenant with id {tenantId} not found");
                }

                // Accept the tenant (set status to Active)
                tenantToAccept.TenantStatus = eRents.Domain.Models.Enums.TenantStatusEnum.Active;
                tenantToAccept.UpdatedAt = DateTime.UtcNow;

                // If property exists, update its status to Occupied
                if (tenantToAccept.PropertyId.HasValue && tenantToAccept.Property != null)
                {
                    tenantToAccept.Property.Status = eRents.Domain.Models.Enums.PropertyStatusEnum.Occupied;
                    tenantToAccept.Property.UpdatedAt = DateTime.UtcNow;
                }

                // Reject all other inactive tenants for the same property
                if (tenantToAccept.PropertyId.HasValue)
                {
                    var otherTenants = await Context.Set<Tenant>()
                        .Where(t => t.PropertyId == tenantToAccept.PropertyId.Value)
                        .Where(t => t.TenantId != tenantId)
                        .Where(t => t.TenantStatus == eRents.Domain.Models.Enums.TenantStatusEnum.Inactive)
                        .ToListAsync();

                    foreach (var otherTenant in otherTenants)
                    {
                        otherTenant.TenantStatus = eRents.Domain.Models.Enums.TenantStatusEnum.Evicted;
                        otherTenant.UpdatedAt = DateTime.UtcNow;
                    }
                }

                await Context.SaveChangesAsync();
                await transaction.CommitAsync();

                return Mapper.Map<TenantResponse>(tenantToAccept);
            }
            catch
            {
                await transaction.RollbackAsync();
                throw;
            }
        }
    }
}